#include "overmapbuffer.h"

#include <algorithm>
#include <cassert>
#include <climits>
#include <cstdint>
#include <iterator>
#include <list>
#include <map>
#include <optional>
#include <queue>
#include <future>

#include "avatar.h"
#include "calendar.h"
#include "cata_utility.h"
#include "character_id.h"
#include "color.h"
#include "map_iterator.h"
#include "numeric_interval.h"
#include "coordinate_conversions.h"
#include "coordinates.h"
#include "debug.h"
#include "distribution_grid.h"
#include "filesystem.h"
#include "game.h"
#include "game_constants.h"
#include "int_id.h"
#include "line.h"
#include "map.h"
#include "memory_fast.h"
#include "mongroup.h"
#include "monster.h"
#include "npc.h"
#include "overmap.h"
#include "overmap_connection.h"
#include "overmap_special.h"
#include "overmap_types.h"
#include "popup.h"
#include "rng.h"
#include "simple_pathfinding.h"
#include "string_formatter.h"
#include "string_id.h"
#include "string_utils.h"
#include "translations.h"
#include "vehicle.h"
#include "vehicle_part.h"
#include "profile.h"
#include "world.h"

class map_extra;

template<typename _Mutex>
using write_lock = std::unique_lock< _Mutex >;
template<typename _Mutex>
using read_lock = std::shared_lock< _Mutex >;

overmapbuffer overmap_buffer;

overmapbuffer::overmapbuffer()
{
}

const city_reference city_reference::invalid{ nullptr, tripoint_abs_sm(), -1 };

int city_reference::get_distance_from_bounds() const
{
    assert( city != nullptr );
    return distance - omt_to_sm_copy( city->size );
}

omt_find_params::~omt_find_params() = default;

omt_route_params::~omt_route_params() = default;

overmap &overmapbuffer::get( const point_abs_om &p )
{
    {
        read_lock<std::shared_mutex> _l( mutex );
        const auto it = overmaps.find( p );
        if( it != overmaps.end() ) {
            return *it->second.get();
        }
    }

    overmap *new_om;
    {
        write_lock<std::shared_mutex> _l( mutex );
        // Search for it again, but now with a lock since another thread could've loaded this overmap tile first
        const auto it = overmaps.find( p );
        if( it != overmaps.end() ) {
            return *it->second.get();
        }

        // That constructor loads an existing overmap or creates a new one.
        assert( overmaps.find( p ) == overmaps.end() );
        overmaps[p] = std::make_unique<overmap>( p );
        new_om = overmaps[p].get();
    }
    // Note: fix_mongroups might load other overmaps, so overmaps.back() is not
    // necessarily the overmap at (x,y)
    new_om->populate();
    fix_mongroups( *new_om );
    fix_npcs( *new_om );

    return *new_om;
}

void overmapbuffer::create_custom_overmap( const point_abs_om &p, overmap_special_batch &specials )
{
    overmap *new_om;
    {
        write_lock<std::shared_mutex> _l( mutex );
        overmaps[p] = std::make_unique<overmap>( p );
        new_om = overmaps[p].get();
    }
    new_om->populate( specials );
}

void overmapbuffer::generate( const std::vector<point_abs_om> &locs )
{
    using overmap_loc = std::pair<point_abs_om, std::unique_ptr<overmap>>;

    std::vector<std::future<overmap_loc>> async_data;
    for( auto &loc : locs ) {
        if( overmap_buffer.has( loc ) ) {
            continue;
        }

        auto gen_func = [&]() {
            auto map = std::make_unique<overmap>( loc );
            map->populate();
            fix_mongroups( *map );
            fix_npcs( *map );
            return std::make_pair( loc, std::move( map ) );
        };
        async_data.push_back( std::async( std::launch::async, gen_func ) );
    }

    auto popup = make_shared_fast<throbber_popup>( _( "Please wait..." ) );
    for( auto &f : async_data ) {
        while( f.wait_for( std::chrono::milliseconds( 10 ) ) != std::future_status::ready ) {
            popup->refresh();
        }
    }

    {
        write_lock<std::shared_mutex> _l( mutex );
        for( auto &m : async_data ) {
            auto result = m.get();
            overmaps[result.first] = std::move( result.second );
        }
    }
}

void overmapbuffer::fix_mongroups( overmap &new_overmap )
{
    for( auto it = new_overmap.zg.begin(); it != new_overmap.zg.end(); ) {
        auto &mg = it->second;
        // spawn related code simply sets population to 0 when they have been
        // transformed into spawn points on a submap, the group can then be removed
        if( mg.empty() ) {
            new_overmap.zg.erase( it++ );
            continue;
        }
        // Inside the bounds of the overmap?
        if( mg.pos.x() >= 0 && mg.pos.y() >= 0 && mg.pos.x() < OMAPX * 2 &&
            mg.pos.y() < OMAPY * 2 ) {
            ++it;
            continue;
        }
        point_abs_sm smabs = project_combine( new_overmap.pos(), mg.pos.xy() );
        point_abs_om omp;
        point_om_sm sm_rem;
        std::tie( omp, sm_rem ) = project_remain<coords::om>( smabs );
        if( !has( omp ) ) {
            // Don't generate new overmaps, as this can be called from the
            // overmap-generating code.
            ++it;
            continue;
        }
        overmap &om = get( omp );
        mg.pos = tripoint_om_sm( sm_rem, mg.pos.z() );
        om.add_mon_group( mg );
        new_overmap.zg.erase( it++ );
    }
}

void overmapbuffer::fix_npcs( overmap &new_overmap )
{
    // First step: move all npcs that are located outside of the given overmap
    // into a separate container. After that loop, new_overmap.npcs is no
    // accessed anymore!
    decltype( overmap::npcs ) to_relocate;
    for( auto it = new_overmap.npcs.begin(); it != new_overmap.npcs.end(); ) {
        npc &np = **it;
        const tripoint_abs_omt npc_omt_pos = np.global_omt_location();
        const point_abs_om npc_om_pos = project_to<coords::om>( npc_omt_pos.xy() );
        const point_abs_om loc = new_overmap.pos();
        if( npc_om_pos == loc ) {
            // Nothing to do
            ++it;
            continue;
        }
        to_relocate.push_back( *it );
        it = new_overmap.npcs.erase( it );
    }
    // Second step: put them back where they belong. This step involves loading
    // new overmaps (via `get`), which does in turn call this function for the
    // newly loaded overmaps. This in turn may move NPCs from the second overmap
    // back into the first overmap. This messes up the iteration of it. The
    // iteration is therefore done in a separate step above (which does *not*
    // involve loading new overmaps).
    for( auto &ptr : to_relocate ) {
        npc &np = *ptr;
        const tripoint_abs_omt npc_omt_pos = np.global_omt_location();
        const point_abs_om npc_om_pos = project_to<coords::om>( npc_omt_pos.xy() );
        const point_abs_om loc = new_overmap.pos();
        if( !has( npc_om_pos ) ) {
            // This can't really happen without save editing
            // We have no sane option here, just place the NPC on the edge
            debugmsg( "NPC %s is out of bounds, on non-generated overmap %s",
                      np.name, loc.to_string() );
            point_abs_sm npc_sm = project_to<coords::sm>( npc_om_pos );
            point_abs_sm min = project_to<coords::sm>( loc );
            point_abs_sm max =
                project_to<coords::sm>( loc + point_south_east ) - point_south_east;
            npc_sm.x() = clamp( npc_sm.x(), min.x(), max.x() );
            npc_sm.y() = clamp( npc_sm.y(), min.y(), max.y() );
            // TODO: fix point types
            np.spawn_at_sm( tripoint_abs_sm( npc_sm, np.posz() ).raw() );
            new_overmap.npcs.push_back( ptr );
            continue;
        }

        // Simplest case: just move the pointer
        get( npc_om_pos ).insert_npc( ptr );
    }
}

void overmapbuffer::save()
{
    read_lock<std::shared_mutex> _l( mutex );

    for( auto &omp : overmaps ) {
        // Note: this may throw io errors from std::ofstream
        omp.second->save();
    }
}

void overmapbuffer::clear()
{
    write_lock<std::shared_mutex> _l( mutex );

    overmaps.clear();
    known_non_existing.clear();
    placed_unique_specials.clear();
}

const regional_settings &overmapbuffer::get_settings( const tripoint_abs_omt &p )
{
    overmap *om = get_om_global( p ).om;
    return om->get_settings();
}

void overmapbuffer::add_note( const tripoint_abs_omt &p, const std::string &message )
{
    overmap_with_local_coords om_loc = get_om_global( p );
    om_loc.om->add_note( om_loc.local, message );
}

void overmapbuffer::delete_note( const tripoint_abs_omt &p )
{
    if( has_note( p ) ) {
        overmap_with_local_coords om_loc = get_om_global( p );
        om_loc.om->delete_note( om_loc.local );
    }
}

void overmapbuffer::mark_note_dangerous( const tripoint_abs_omt &p, int radius, bool is_dangerous )
{
    if( has_note( p ) ) {
        overmap_with_local_coords om_loc = get_om_global( p );
        om_loc.om->mark_note_dangerous( om_loc.local, radius, is_dangerous );
    }
}

void overmapbuffer::add_extra( const tripoint_abs_omt &p, const string_id<map_extra> &id )
{
    overmap_with_local_coords om_loc = get_om_global( p );
    om_loc.om->add_extra( om_loc.local, id );
}

void overmapbuffer::delete_extra( const tripoint_abs_omt &p )
{
    if( has_extra( p ) ) {
        overmap_with_local_coords om_loc = get_om_global( p );
        om_loc.om->delete_extra( om_loc.local );
    }
}

overmap *overmapbuffer::get_existing( const point_abs_om &p )
{
    {
        read_lock<std::shared_mutex> _l( mutex );
        const auto it = overmaps.find( p );
        if( it != overmaps.end() ) {
            return it->second.get();
        }

        if( known_non_existing.contains( p ) ) {
            // This overmap does not exist on disk (this has already been
            // checked in a previous call of this function).
            return nullptr;
        }
    }
    if( g->get_active_world() && g->get_active_world()->overmap_exists( p ) ) {
        // File exists, load it normally (the get function
        // indirectly call overmap::open to do so).
        return &get( p );
    }
    // File does not exist (or not readable which is essentially
    // the same for our usage). A second call of this function with
    // the same coordinates will not check the file system, and
    // return early.
    // If the overmap had been created in the mean time, the previous
    // loop would have found and returned it.
    {
        write_lock<std::shared_mutex> _l( mutex );
        known_non_existing.insert( p );
    }
    return nullptr;
}

bool overmapbuffer::has( const point_abs_om &p )
{
    return get_existing( p ) != nullptr;
}

overmap_with_local_coords
overmapbuffer::get_om_global( const point_abs_omt &p )
{
    return get_om_global( tripoint_abs_omt( p, 0 ) );
}

overmap_with_local_coords
overmapbuffer::get_om_global( const tripoint_abs_omt &p )
{
    point_abs_om om_pos;
    point_om_omt local;
    std::tie( om_pos, local ) = project_remain<coords::om>( p.xy() );
    overmap *om = &get( om_pos );
    return { om, tripoint_om_omt( local, p.z() ) };
}

overmap_with_local_coords
overmapbuffer::get_existing_om_global( const point_abs_omt &p )
{
    return get_existing_om_global( tripoint_abs_omt( p, 0 ) );
}

overmap_with_local_coords
overmapbuffer::get_existing_om_global( const tripoint_abs_omt &p )
{
    point_abs_om om_pos;
    point_om_omt local;
    std::tie( om_pos, local ) = project_remain<coords::om>( p.xy() );
    overmap *om = get_existing( om_pos );
    if( om == nullptr ) {
        return overmap_with_local_coords{ nullptr, tripoint_om_omt() };
    }

    return overmap_with_local_coords{ om, tripoint_om_omt( local, p.z() ) };
}

bool overmapbuffer::is_omt_generated( const tripoint_abs_omt &loc )
{
    if( overmap_with_local_coords om_loc = get_existing_om_global( loc ) ) {
        return om_loc.om->is_omt_generated( om_loc.local );
    }

    // If the overmap doesn't exist, then for sure the local mapgen
    // hasn't happened.
    return false;
}

bool overmapbuffer::has_note( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->has_note( om_loc.local );
    }
    return false;
}

std::optional<int> overmapbuffer::has_note_with_danger_radius( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->has_note_with_danger_radius( om_loc.local );
    }
    return std::nullopt;
}

bool overmapbuffer::is_marked_dangerous( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->is_marked_dangerous( om_loc.local );
    }
    return false;
}

const std::string &overmapbuffer::note( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->note( om_loc.local );
    }
    static const std::string empty_string;
    return empty_string;
}

bool overmapbuffer::has_extra( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->has_extra( om_loc.local );
    }
    return false;
}

const string_id<map_extra> &overmapbuffer::extra( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->extra( om_loc.local );
    }
    static const string_id<map_extra> id;
    return id;
}

bool overmapbuffer::is_explored( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->is_explored( om_loc.local );
    }
    return false;
}

void overmapbuffer::toggle_explored( const tripoint_abs_omt &p )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    om_loc.om->explored( om_loc.local ) = !om_loc.om->explored( om_loc.local );
}

bool overmapbuffer::is_path( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->is_path( om_loc.local );
    }
    return false;
}

void overmapbuffer::toggle_path( const tripoint_abs_omt &p )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    om_loc.om->path( om_loc.local ) = !om_loc.om->path( om_loc.local );
}

bool overmapbuffer::has_horde( const tripoint_abs_omt &p )
{
    for( const auto &m : overmap_buffer.monsters_at( p ) ) {
        if( m->horde ) {
            return true;
        }
    }

    return false;
}

int overmapbuffer::get_horde_size( const tripoint_abs_omt &p )
{
    int horde_size = 0;
    for( const auto &m : overmap_buffer.monsters_at( p ) ) {
        if( m->horde ) {
            if( !m->monsters.empty() ) {
                horde_size += m->monsters.size();
            } else {
                // We don't know how large this will actually be, because
                // population "1" can still result in a zombie pack.
                // So we double the population as an estimate to make
                // hordes more likely to be visible on the overmap.
                horde_size += m->population * 2;
            }
        }
    }

    return horde_size;
}

bool overmapbuffer::has_vehicle( const tripoint_abs_omt &p )
{
    if( p.z() ) {
        return false;
    }

    const overmap_with_local_coords om_loc = get_existing_om_global( p );
    if( !om_loc ) {
        return false;
    }

    for( const auto &v : om_loc.om->vehicles ) {
        if( v.second.p == om_loc.local.xy() ) {
            return true;
        }
    }

    return false;
}

std::vector<om_vehicle> overmapbuffer::get_vehicle( const tripoint_abs_omt &p )
{
    std::vector<om_vehicle> result;
    if( p.z() != 0 ) {
        return result;
    }
    const overmap_with_local_coords om_loc = get_existing_om_global( p );
    if( !om_loc ) {
        return result;
    }
    for( const auto &ov : om_loc.om->vehicles ) {
        if( ov.second.p == om_loc.local.xy() ) {
            result.push_back( ov.second );
        }
    }
    return result;
}

void overmapbuffer::signal_hordes( const tripoint_abs_sm &center, const int sig_power )
{
    const auto radius = sig_power;
    for( auto &om : get_overmaps_near( center, radius ) ) {
        const point_abs_sm abs_pos_om = project_to<coords::sm>( om->pos() );
        const tripoint_rel_sm rel_pos = center - abs_pos_om;
        // overmap::signal_hordes expects a coordinate relative to the overmap, this is easier
        // for processing as the monster group stores is location as relative coordinates, too.
        om->signal_hordes( rel_pos, sig_power );
    }
}

void overmapbuffer::process_mongroups()
{
    ZoneScoped;
    // arbitrary radius to include nearby overmaps (aside from the current one)
    const auto radius = MAPSIZE * 2;
    // TODO: fix point types
    const tripoint_abs_sm center( get_player_character().global_sm_location() );
    for( auto &om : get_overmaps_near( center, radius ) ) {
        om->process_mongroups();
    }
}

void overmapbuffer::move_hordes()
{
    ZoneScoped;

    // arbitrary radius to include nearby overmaps (aside from the current one)
    const auto radius = MAPSIZE * 2;
    // TODO: fix point types
    const tripoint_abs_sm center( get_player_character().global_sm_location() );
    for( auto &om : get_overmaps_near( center, radius ) ) {
        om->move_hordes();
    }
}

std::vector<mongroup *> overmapbuffer::monsters_at( const tripoint_abs_omt &p )
{
    // (x,y) are overmap terrain coordinates, they spawn 2x2 submaps,
    // but monster groups are defined with submap coordinates.
    tripoint_abs_sm p_sm = project_to<coords::sm>( p );
    std::vector<mongroup *> result;
    for( point offset : std::array<point, 4> { { { point_zero }, { point_south }, { point_east }, { point_south_east } } } ) {
        std::vector<mongroup *> tmp = groups_at( p_sm + offset );
        result.insert( result.end(), tmp.begin(), tmp.end() );
    }
    return result;
}

std::vector<mongroup *> overmapbuffer::groups_at( const tripoint_abs_sm &p )
{
    std::vector<mongroup *> result;
    point_om_sm sm_within_om;
    point_abs_om omp;
    std::tie( omp, sm_within_om ) = project_remain<coords::om>( p.xy() );
    if( !has( omp ) ) {
        return result;
    }
    overmap &om = get( omp );
    auto groups_range = om.zg.equal_range( tripoint_om_sm( sm_within_om, p.z() ) );
    for( auto it = groups_range.first; it != groups_range.second; ++it ) {
        mongroup &mg = it->second;
        if( mg.empty() ) {
            continue;
        }
        result.push_back( &mg );
    }
    return result;
}

std::array<std::array<scent_trace, 3>, 3> overmapbuffer::scents_near( const tripoint_abs_omt
        &origin )
{
    std::array<std::array<scent_trace, 3>, 3> found_traces;

    for( int x = -1; x <= 1 ; ++x ) {
        for( int y = -1; y <= 1; ++y ) {
            tripoint_abs_omt iter = origin + point( x, y );
            found_traces[x + 1][y + 1] = scent_at( iter );
        }
    }

    return found_traces;
}

scent_trace overmapbuffer::scent_at( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->scent_at( p );
    }
    return scent_trace();
}

void overmapbuffer::set_scent( const tripoint_abs_omt &loc, int strength )
{
    const overmap_with_local_coords om_loc = get_om_global( loc );
    scent_trace new_scent( calendar::turn, strength );
    om_loc.om->set_scent( loc, new_scent );
}

void overmapbuffer::move_vehicle( vehicle *veh, const point_abs_ms &old_msp )
{
    const point_abs_ms new_msp = veh->global_square_location().xy();
    const point_abs_omt old_omt = project_to<coords::omt>( old_msp );
    const point_abs_omt new_omt = project_to<coords::omt>( new_msp );
    const overmap_with_local_coords old_om_loc = get_om_global( old_omt );
    const overmap_with_local_coords new_om_loc = get_om_global( new_omt );
    if( old_om_loc.om == new_om_loc.om ) {
        new_om_loc.om->vehicles[veh->om_id].p = new_om_loc.local.xy();
    } else {
        old_om_loc.om->vehicles.erase( veh->om_id );
        add_vehicle( veh );
    }
}

void overmapbuffer::remove_vehicle( const vehicle *veh )
{
    const tripoint_abs_omt omt = veh->global_omt_location();
    const overmap_with_local_coords om_loc = get_existing_om_global( omt );
    if( !om_loc.om ) {
        debugmsg( "Can't find overmap for vehicle at %s", omt.to_string() );
        return;
    }
    om_loc.om->vehicles.erase( veh->om_id );
}

void overmapbuffer::add_vehicle( vehicle *veh )
{
    const tripoint_abs_omt omt = veh->global_omt_location();
    const overmap_with_local_coords om_loc = get_existing_om_global( omt );
    if( !om_loc.om ) {
        debugmsg( "Can't find overmap for vehicle at %s", omt.to_string() );
        return;
    }
    int id = om_loc.om->vehicles.size() + 1;
    // this *should* be unique but just in case
    while( om_loc.om->vehicles.contains( id ) ) {
        id++;
    }
    om_vehicle &tracked_veh = om_loc.om->vehicles[id];
    tracked_veh.p = om_loc.local.xy();
    tracked_veh.name = veh->name;
    veh->om_id = id;
}

bool overmapbuffer::seen( const tripoint_abs_omt &p )
{
    if( const overmap_with_local_coords om_loc = get_existing_om_global( p ) ) {
        return om_loc.om->seen( om_loc.local );
    }
    return false;
}

void overmapbuffer::set_seen( const tripoint_abs_omt &p, bool seen )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    om_loc.om->seen( om_loc.local ) = seen;
}

const oter_id &overmapbuffer::ter( const tripoint_abs_omt &p )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    return om_loc.om->ter( om_loc.local );
}

const oter_id &overmapbuffer::ter_existing( const tripoint_abs_omt &p )
{
    static const oter_id ot_null;
    const overmap_with_local_coords om_loc = get_existing_om_global( p );
    if( !om_loc.om ) {
        return ot_null;
    }
    return om_loc.om->ter( om_loc.local );
}

void overmapbuffer::ter_set( const tripoint_abs_omt &p, const oter_id &id )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    return om_loc.om->ter_set( om_loc.local, id );
}

std::string *overmapbuffer::join_used_at( const std::pair<tripoint_abs_omt, cube_direction> &p )
{
    const overmap_with_local_coords om_loc = get_om_global( p.first );
    return om_loc.om->join_used_at( { om_loc.local, p.second } );
}

std::optional<mapgen_arguments> *overmapbuffer::mapgen_args( const tripoint_abs_omt &p )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    return om_loc.om->mapgen_args( om_loc.local );
}

bool overmapbuffer::reveal( const point_abs_omt &center, int radius, int z )
{
    return reveal( tripoint_abs_omt( center, z ), radius );
}

bool overmapbuffer::reveal( const tripoint_abs_omt &center, int radius )
{
    return reveal( center, radius, []( const oter_id & ) {
        return true;
    } );
}

bool overmapbuffer::reveal( const tripoint_abs_omt &center, int radius,
                            const std::function<bool( const oter_id & )> &filter )
{
    int radius_squared = radius * radius;
    bool result = false;
    for( int i = -radius; i <= radius; i++ ) {
        for( int j = -radius; j <= radius; j++ ) {
            const tripoint_abs_omt p = center + point( i, j );
            if( seen( p ) ) {
                continue;
            }
            if( trigdist && i * i + j * j > radius_squared ) {
                continue;
            }
            if( !filter( ter( p ) ) ) {
                continue;
            }
            result = true;
            set_seen( p, true );
        }
    }
    return result;
}

overmap_path_params overmap_path_params::for_player()
{
    overmap_path_params ret;
    ret.road_cost = 10;
    ret.dirt_road_cost = 10;
    ret.field_cost = 15;
    ret.trail_cost = 18;
    ret.shore_cost = 20;
    ret.small_building_cost = 20;
    ret.forest_cost = 30;
    ret.swamp_cost = 100;
    ret.other_cost = 30;
    return ret;
}

overmap_path_params overmap_path_params::for_npc()
{
    overmap_path_params ret = overmap_path_params::for_player();
    ret.only_known_by_player = false;
    ret.avoid_danger = false;
    return ret;
}

overmap_path_params overmap_path_params::for_land_vehicle( float offroad_coeff, bool tiny,
        bool amphibious )
{
    const bool can_offroad = offroad_coeff >= 0.05;
    overmap_path_params ret;
    ret.road_cost = 10;
    ret.field_cost = can_offroad ? std::lround( 15 / std::min( 1.0f, offroad_coeff ) ) : -1;
    ret.dirt_road_cost = ret.field_cost;
    ret.forest_cost = -1;
    ret.small_building_cost = ( can_offroad && tiny ) ? ret.field_cost + 30 : -1;
    ret.swamp_cost = -1;
    ret.trail_cost = ( can_offroad && tiny ) ? ret.field_cost + 10 : -1;
    if( amphibious ) {
        const overmap_path_params boat_params = overmap_path_params::for_watercraft();
        ret.water_cost = boat_params.water_cost;
        ret.shore_cost = boat_params.shore_cost;
    }
    return ret;
}

overmap_path_params overmap_path_params::for_watercraft()
{
    overmap_path_params ret;
    ret.water_cost = 10;
    ret.shore_cost = 20;
    return ret;
}

overmap_path_params overmap_path_params::for_aircraft()
{
    overmap_path_params ret;
    ret.air_cost = 10;
    return ret;
}

static int get_terrain_cost( const tripoint_abs_omt &omt_pos, const overmap_path_params &params )
{
    if( params.only_known_by_player && !overmap_buffer.seen( omt_pos ) ) {
        return -1;
    }
    if( params.avoid_danger && overmap_buffer.is_marked_dangerous( omt_pos ) ) {
        return -1;
    }
    const oter_id &oter = overmap_buffer.ter_existing( omt_pos );
    if( is_ot_match( "road", oter, ot_match_type::type ) ||
        is_ot_match( "bridge", oter, ot_match_type::type ) ||
        is_ot_match( "bridge_road", oter, ot_match_type::type ) ||
        is_ot_match( "bridgehead_ground", oter, ot_match_type::type ) ||
        is_ot_match( "bridgehead_ramp", oter, ot_match_type::type ) ||
        is_ot_match( "road_nesw_manhole", oter, ot_match_type::type ) ||
        overmap_buffer.is_path( omt_pos ) ) {
        return params.road_cost;
    } else if( is_ot_match( "field", oter, ot_match_type::type ) ) {
        return params.field_cost;
    } else if( is_ot_match( "rural_road", oter, ot_match_type::prefix ) ||
               is_ot_match( "dirt_road", oter, ot_match_type::prefix ) ||
               is_ot_match( "subway", oter, ot_match_type::type ) ||
               is_ot_match( "lab_subway", oter, ot_match_type::type ) ) {
        return params.dirt_road_cost;
    } else if( is_ot_match( "forest_trail", oter, ot_match_type::type ) ) {
        return params.trail_cost;
    } else if( is_ot_match( "forest_water", oter, ot_match_type::type ) ) {
        return params.swamp_cost;
    } else if( is_ot_match( "river", oter, ot_match_type::prefix ) ||
               is_ot_match( "lake", oter, ot_match_type::prefix ) ) {
        if( is_ot_match( "river_center", oter, ot_match_type::type ) ||
            is_ot_match( "lake_surface", oter, ot_match_type::type ) ) {
            return params.water_cost;
        } else {
            return params.shore_cost;
        }
    } else if( is_ot_match( "bridge_under", oter, ot_match_type::type ) ) {
        return params.water_cost;
    } else if( is_ot_match( "open_air", oter, ot_match_type::type ) ) {
        return params.air_cost;
    } else if( is_ot_match( "forest", oter, ot_match_type::type ) ) {
        return params.forest_cost;
    } else if( is_ot_match( "empty_rock", oter, ot_match_type::type ) ||
               is_ot_match( "deep_rock", oter, ot_match_type::type ) ||
               is_ot_match( "solid_earth", oter, ot_match_type::type ) ||
               is_ot_match( "microlab_rock_border", oter, ot_match_type::type ) ) {
        return -1;
    } else {
        return params.other_cost;
    }
}

static bool is_ramp( const tripoint_abs_omt &omt_pos )
{
    const oter_id &oter = overmap_buffer.ter_existing( omt_pos );
    return is_ot_match( "bridgehead_ground", oter, ot_match_type::type ) ||
           is_ot_match( "bridgehead_ramp", oter, ot_match_type::type );
}

std::vector<tripoint_abs_omt> overmapbuffer::get_travel_path(
    const tripoint_abs_omt &src, const tripoint_abs_omt &dest, overmap_path_params params )
{
    if( src == overmap::invalid_tripoint || dest == overmap::invalid_tripoint ) {
        return {};
    }

    const pf::omt_scoring_fn estimate = [&]( tripoint_abs_omt pos ) {
        const int cur_cost = pos == src ? 0 : get_terrain_cost( pos, params );
        if( cur_cost < 0 ) {
            return pf::omt_score::rejected;
        }
        return pf::omt_score( cur_cost, is_ramp( pos ) );
    };

    constexpr int radius = 4 * OMAPX; // radius of search in OMTs = 4 overmaps
    const pf::simple_path<tripoint_abs_omt> path = pf::find_overmap_path( src, dest, radius, estimate );
    return path.points;
}

bool overmapbuffer::reveal_route( const tripoint_abs_omt &source, const tripoint_abs_omt &dest,
                                  const omt_route_params &params )
{
    // Maximal radius of search (in overmaps)
    static const int RADIUS = 4;
    // half-size of the area to search in
    static const point_rel_omt O( RADIUS * OMAPX, RADIUS * OMAPY );

    if( source == overmap::invalid_tripoint || dest == overmap::invalid_tripoint ) {
        return false;
    }

    // Local source - center of the local area
    const point_rel_omt start( O );
    // To convert local coordinates to global ones
    const tripoint_abs_omt base = source - start;
    // Local destination - relative to base
    const point_rel_omt finish = ( dest - base ).xy();

    const auto get_ter_at = [&]( const point_rel_omt & p ) {
        return ter( base + p );
    };

    const oter_id oter = get_ter_at( start );
    const auto connection = overmap_connections::guess_for( oter );

    if( !connection ) {
        return false;
    }

    const pf::two_node_scoring_fn<point_rel_omt> estimate =
    [&]( pf::directed_node<point_rel_omt> cur, std::optional<pf::directed_node<point_rel_omt>> ) {
        int cost = 0;
        const oter_id oter = get_ter_at( cur.pos );
        if( !connection->has( oter ) ) {
            if( params.road_only ) {
                return pf::node_score::rejected;
            }
            if( is_river( oter ) ) {
                return pf::node_score::rejected; // Can't walk on water
            }
            // Allow going slightly off-road to overcome small obstacles (e.g. craters),
            // but heavily penalize that to make roads preferable
            cost = 250;
        }
        return pf::node_score( cost, manhattan_dist( finish, cur.pos ) );
    };

    // TODO: use overmapbuffer::get_travel_path() with appropriate params instead
    // TODO: tick params.popup
    const auto path = pf::greedy_path( start, finish, O * 2, estimate );

    for( const auto &node : path.nodes ) {
        reveal( base + node.pos, params.radius );
    }
    return !path.nodes.empty();
}

bool overmapbuffer::check_ot_existing( const std::string &type, ot_match_type match_type,
                                       const tripoint_abs_omt &loc )
{
    const overmap_with_local_coords om_loc = get_existing_om_global( loc );
    if( !om_loc ) {
        return false;
    }
    return om_loc.om->check_ot( type, match_type, om_loc.local );
}

bool overmapbuffer::check_overmap_special_type_existing(
    const overmap_special_id &id, const tripoint_abs_omt &loc )
{
    const overmap_with_local_coords om_loc = get_existing_om_global( loc );
    if( !om_loc ) {
        return false;
    }
    return om_loc.om->check_overmap_special_type( id, om_loc.local );
}

std::optional<overmap_special_id> overmapbuffer::overmap_special_at(
    const tripoint_abs_omt &loc )
{
    const overmap_with_local_coords om_loc = get_om_global( loc );
    return om_loc.om->overmap_special_at( om_loc.local );
}

bool overmapbuffer::check_ot( const std::string &type, ot_match_type match_type,
                              const tripoint_abs_omt &p )
{
    const overmap_with_local_coords om_loc = get_om_global( p );
    return om_loc.om->check_ot( type, match_type, om_loc.local );
}

bool overmapbuffer::check_overmap_special_type( const overmap_special_id &id,
        const tripoint_abs_omt &loc )
{
    const overmap_with_local_coords om_loc = get_om_global( loc );
    return om_loc.om->check_overmap_special_type( id, om_loc.local );
}

void overmapbuffer::add_unique_special( const overmap_special_id &id )
{
    if( contains_unique_special( id ) ) {
        debugmsg( "Unique overmap special placed more than once: %s", id.str() );
    }
    placed_unique_specials.emplace( id );
}

bool overmapbuffer::contains_unique_special( const overmap_special_id &id ) const
{
    return placed_unique_specials.contains( id );
}

bool overmapbuffer::is_findable_location( const tripoint_abs_omt &location,
        const omt_find_params &params )
{
    overmap_with_local_coords om_loc;
    if( params.existing_only ) {
        om_loc = get_existing_om_global( location );
    } else {
        om_loc = get_om_global( location );
    }

    return is_findable_location( om_loc, params );
}

bool overmapbuffer::is_findable_location( const overmap_with_local_coords &om_loc,
        const omt_find_params &params )
{
    if( om_loc.om == nullptr ) {
        return false;
    }

    const auto is_seen = om_loc.om->seen( om_loc.local );
    if( params.seen.has_value() && params.seen.value() != is_seen ) {
        return false;
    }

    const auto is_explored = om_loc.om->explored( om_loc.local );
    if( params.explored.has_value() && params.explored.value() != is_explored ) {
        return false;
    }

    bool is_excluded = false;
    for( const std::pair<std::string, ot_match_type> &elem : params.exclude_types ) {
        is_excluded = om_loc.om->check_ot( elem.first, elem.second, om_loc.local );
        if( is_excluded ) {
            break;
        }
    }
    if( is_excluded ) {
        return false;
    }

    bool is_included = false;
    for( const std::pair<std::string, ot_match_type> &elem : params.types ) {
        is_included = om_loc.om->check_ot( elem.first, elem.second, om_loc.local );
        if( is_included ) {
            break;
        }
    }
    if( !is_included ) {
        return false;
    }

    if( params.om_special ) {
        bool meets_om_special = om_loc.om->check_overmap_special_type( *params.om_special, om_loc.local );
        if( !meets_om_special ) {
            return false;
        }
    }

    return true;
}

namespace
{
using find_task = std::pair
                  <point_abs_om, std::vector<std::pair<tripoint_abs_omt, tripoint_om_omt>>>;

struct find_task_generator {
    const spiral_generator<point> _gen;
    const int _min_z;
    const int _max_z;
    const int _max_coords;
    const int _n_steps;
    spiral_generator<point>::iterator _it;
    const spiral_generator<point>::iterator _end;
    std::pair<point_abs_om, point_om_omt> _current;
    bool _done;

    auto get_om_loc() {
        auto &p = *_it;
        tripoint_abs_omt loc( p.x, p.y, 0 );
        point_abs_om om_pos;
        point_om_omt local;
        std::tie( om_pos, local ) = project_remain<coords::om>( loc.xy() );
        return std::make_pair( om_pos, local );
    }

    find_task_generator( point p, int mind, int maxd, int minz, int maxz, int chunk )
        : _gen( p, mind, maxd )
        , _min_z( minz )
        , _max_z( maxz )
        , _max_coords( chunk )
        , _n_steps( chunk / ( maxz - minz + 1 ) )
        , _it( _gen.begin() )
        , _end( _gen.end() ) {
        _current = get_om_loc();
        _done = _end == _it;
    }

    std::optional<find_task> operator()() {
        if( _done ) {
            return std::nullopt;
        }

        std::vector<std::pair<tripoint_abs_omt, tripoint_om_omt>> v;
        v.reserve( _max_coords );
        point_abs_om om_loc = _current.first;

        for( int n = 0; n < _n_steps; n++ ) {
            auto &p = *_it;
            for( int z = _min_z; z <= _max_z; z++ ) {
                tripoint_abs_omt abs( p.x, p.y, z );
                tripoint_om_omt om( _current.second, z );
                v.emplace_back( abs, om );
            }

            ++_it;
            _current = get_om_loc();
            _done = _end == _it;
            if( _done || _current.first != om_loc ) {
                break;
            }
        }

        return std::make_pair( om_loc, std::move( v ) );
    }
};
}

std::vector<tripoint_abs_omt> overmapbuffer::find_all( const tripoint_abs_omt &origin,
        const omt_find_params &params )
{
    const auto concurrency = std::max( 1u, std::thread::hardware_concurrency() - 1 );
    if( concurrency == 1 ) {
        return find_all_sync( origin, params );
    } else {
        return find_all_async( origin, params );
    }
}

std::vector<tripoint_abs_omt> overmapbuffer::find_all_sync( const tripoint_abs_omt &origin,
        const omt_find_params &params )
{
    // max_dist == 0 means search a whole overmap diameter.
    const int min_dist = params.search_range.first;
    const int max_dist = params.search_range.second ? params.search_range.second : OMAPX;

    // empty search_layers means origin.z
    const auto search_layers = params.search_layers.value_or( std::make_pair( origin.z(),
                               origin.z() ) );
    const int min_layer = search_layers.first;
    const int max_layer = search_layers.second;

    find_task_generator gen( origin.raw().xy(), min_dist, max_dist, min_layer, max_layer, 256 );

    std::vector<tripoint_abs_omt> find_result;
    find_result.reserve( params.max_results.value_or( 256 ) );
    while( true ) {

        if( params.popup ) {
            params.popup->refresh();
        }

        auto task_data = gen();
        if( !task_data.has_value() ) {
            break;
        }

        auto& [task_om, task_omts] = task_data.value();
        if( params.existing_only && !has( task_om ) ) {
            continue;
        }

        overmap *om_loc = &get( task_om );

        bool done = false;
        for( const auto &loc : task_omts ) {
            overmap_with_local_coords q{ om_loc, loc.second };
            if( is_findable_location( q, params ) ) {
                find_result.push_back( loc.first );
            }
            if( params.max_results.has_value() &&
                find_result.size() == static_cast<size_t>( params.max_results.value() ) ) {
                done = true;
                break;
            }
        }

        if( done ) {
            break;
        }
    }

    return find_result;
}

std::vector<tripoint_abs_omt> overmapbuffer::find_all_async( const tripoint_abs_omt &origin,
        const omt_find_params &params )
{
    // max_dist == 0 means search a whole overmap diameter.
    const int min_dist = params.search_range.first;
    const int max_dist = params.search_range.second ? params.search_range.second : OMAPX;

    // empty search_layers means origin.z
    const auto search_layers = params.search_layers.value_or( std::make_pair( origin.z(),
                               origin.z() ) );
    const int min_layer = search_layers.first;
    const int max_layer = search_layers.second;
    // const int num_layers = max_layer - min_layer + 1;

    find_task_generator gen( origin.raw().xy(), min_dist, max_dist, min_layer, max_layer, 256 );

    std::deque<std::future<std::vector<tripoint_abs_omt>>> tasks;

    std::vector<tripoint_abs_omt> find_result;
    int free_tasks = std::max( 1u, std::thread::hardware_concurrency() - 1 );
    auto try_finish_task = []( std::future<std::vector<tripoint_abs_omt>> &task,
    std::vector<tripoint_abs_omt> &dst, omt_find_params params ) -> bool {
        if( task.wait_for( std::chrono::milliseconds( 0 ) ) == std::future_status::ready )
        {
            auto task_result = task.get();

            if( !params.max_results.has_value() ||
                dst.size() < static_cast<size_t>( params.max_results.value() ) ) {
                std::ranges::copy( task_result, std::back_inserter( dst ) );
                if( params.max_results.has_value() &&
                    dst.size() > static_cast<uint64_t>( params.max_results.value() ) ) {
                    dst.resize( params.max_results.value() );
                }
            }

            return true;
        }
        return false;
    };

    while( true ) {
        if( params.popup ) {
            params.popup->refresh();
        }

        if( !tasks.empty() ) {
            if( try_finish_task( tasks.front(), find_result, params ) ) {
                tasks.pop_front();
                ++free_tasks;
            }
            if( params.max_results.has_value() &&
                find_result.size() >= static_cast<uint64_t>( params.max_results.value() ) ) {
                break;
            }
        }

        if( free_tasks == 0 ) {
            continue;
        }

        auto task_data = gen();
        if( !task_data.has_value() ) {
            break;
        }

        auto& [task_om, task_omts] = task_data.value();

        if( params.existing_only && !has( task_om ) ) {
            continue;
        }

        auto task_func = [&]( point_abs_om l,
        std::vector<std::pair<tripoint_abs_omt, tripoint_om_omt>> locals ) {
            std::vector<tripoint_abs_omt> result;

            overmap *om_loc;
            if( params.existing_only ) {
                om_loc = get_existing( l );
            } else {
                om_loc = &get( l );
            }
            if( !om_loc ) {
                return result;
            }

            for( const auto &loc : locals ) {
                overmap_with_local_coords q{ om_loc, loc.second };
                if( is_findable_location( q, params ) ) {
                    result.push_back( loc.first );
                }
                if( params.max_results.has_value() &&
                    result.size() == static_cast<uint64_t>( params.max_results.value() ) ) {
                    break;
                }
            }

            return result;
        };

        auto task = std::async( std::launch::async, task_func, task_om, std::move( task_omts ) );

        tasks.push_back( std::move( task ) );

        --free_tasks;
    }

    while( !tasks.empty() ) {
        if( params.popup ) {
            params.popup->refresh();
        }

        if( try_finish_task( tasks.front(), find_result, params ) ) {
            tasks.pop_front();
            ++free_tasks;
        }
    }

    return find_result;
}

tripoint_abs_omt overmapbuffer::find_closest( const tripoint_abs_omt &origin,
        const omt_find_params &pp )
{
    // Check the origin before searching adjacent tiles!
    if( pp.search_range.first == 0 && is_findable_location( origin, pp ) ) {
        return origin;
    }

    // By default search overmaps within a radius of 4,
    // i.e. C = current overmap, X = overmaps searched:
    //
    // XXXXXXXXX
    // XXXXXXXXX
    // XXXXXXXXX
    // XXXXXXXXX
    // XXXXCXXXX
    // XXXXXXXXX
    // XXXXXXXXX
    // XXXXXXXXX
    // XXXXXXXXX
    //
    // See overmap::place_specials for how we attempt to insure specials are placed within this
    // range.  The actual number is 5 because 1 covers the current overmap,
    // and each additional one expends the search to the next concentric circle of overmaps.

    omt_find_params params = pp;
    if( params.search_range.second == 0 ) {
        params.search_range.second = OMAPX * 5;
    }
    if( !params.max_results.has_value() ) {
        // Limit potential random sample size, scaling with number of terrain types
        params.max_results = 10 * pp.types.size();
    }

    auto scan_result = find_all( origin, params );

    if( scan_result.empty() ) {
        return overmap::invalid_tripoint;
    }

    std::vector<tripoint_abs_omt> near_points;
    int min_dist = INT_MAX;

    // Only care about the absolute nearest points, so only keep those points
    for( auto &p : scan_result ) {
        int dist = square_dist( origin, p );
        if( dist < min_dist ) {
            near_points.clear();
            min_dist = dist;
        } else if( dist > min_dist ) {
            continue;
        }
        near_points.emplace_back( p );
    }

    // rng is inclusive
    auto random_idx = rng( 0, near_points.size() - 1 );
    return near_points[random_idx];
}

tripoint_abs_omt overmapbuffer::find_random( const tripoint_abs_omt &origin,
        const omt_find_params &params )
{
    auto found = find_all( origin, params );
    return random_entry( found, overmap::invalid_tripoint );
}

shared_ptr_fast<npc> overmapbuffer::find_npc( character_id id )
{
    for( auto &it : overmaps ) {
        if( auto p = it.second->find_npc( id ) ) {
            return p;
        }
    }
    return nullptr;
}

void overmapbuffer::insert_npc( const shared_ptr_fast<npc> &who )
{
    assert( who );
    const tripoint_abs_omt npc_omt_pos = who->global_omt_location();
    const point_abs_om npc_om_pos = project_to<coords::om>( npc_omt_pos.xy() );
    get( npc_om_pos ).insert_npc( who );
}

shared_ptr_fast<npc> overmapbuffer::remove_npc( const character_id &id )
{
    for( auto &it : overmaps ) {
        if( const auto p = it.second->erase_npc( id ) ) {
            return p;
        }
    }
    debugmsg( "overmapbuffer::remove_npc: NPC (%d) not found.", id.get_value() );
    return nullptr;
}

std::vector<shared_ptr_fast<npc>> overmapbuffer::get_npcs_near_player( int radius )
{
    tripoint_abs_omt plpos_omt = get_player_character().global_omt_location();
    // get_npcs_near needs submap coordinates
    tripoint_abs_sm plpos = project_to<coords::sm>( plpos_omt );
    // INT_MIN is a (a bit ugly) way to inform get_npcs_near not to filter by z-level
    const int zpos = get_map().has_zlevels() ? INT_MIN : plpos.z();
    return get_npcs_near( tripoint_abs_sm( plpos.xy(), zpos ), radius );
}

std::vector<overmap *> overmapbuffer::get_overmaps_near( const tripoint_abs_sm &location,
        const int radius )
{
    // Grab the corners of a square around the target location at distance radius.
    // Convert to overmap coordinates and iterate from the minimum to the maximum.
    const point_abs_om start =
        project_to<coords::om>( location.xy() + point( -radius, -radius ) );
    const point_abs_om end =
        project_to<coords::om>( location.xy() + point( radius, radius ) );
    const point_rel_om offset = end - start;

    std::vector<overmap *> result;
    result.reserve( ( offset.x() + 1 ) * ( offset.y() + 1 ) );

    for( int x = start.x(); x <= end.x(); ++x ) {
        for( int y = start.y(); y <= end.y(); ++y ) {
            if( overmap *existing_om = get_existing( point_abs_om( x, y ) ) ) {
                result.emplace_back( existing_om );
            }
        }
    }

    // Sort the resulting overmaps so that the closest ones are first.
    const tripoint_abs_om center = project_to<coords::om>( location );
    std::ranges::sort( result, [&center]( const overmap * lhs,
    const overmap * rhs ) {
        const tripoint_abs_om lhs_pos( lhs->pos(), 0 );
        const tripoint_abs_om rhs_pos( rhs->pos(), 0 );
        return trig_dist( center, lhs_pos ) < trig_dist( center, rhs_pos );
    } );

    return result;
}

std::vector<overmap *> overmapbuffer::get_overmaps_near( const point_abs_sm &p, const int radius )
{
    return get_overmaps_near( tripoint_abs_sm( p, 0 ), radius );
}

std::vector<shared_ptr_fast<npc>> overmapbuffer::get_companion_mission_npcs( int range )
{
    std::vector<shared_ptr_fast<npc>> available;
    // TODO: this is an arbitrary radius, replace with something sane.
    for( const auto &guy : get_npcs_near_player( range ) ) {
        if( guy->has_companion_mission() ) {
            available.push_back( guy );
        }
    }
    return available;
}

// If z == INT_MIN, allow all z-levels
std::vector<shared_ptr_fast<npc>> overmapbuffer::get_npcs_near( const tripoint_abs_sm &p,
                               int radius )
{
    std::vector<shared_ptr_fast<npc>> result;
    for( auto &it : get_overmaps_near( p.xy(), radius ) ) {
        auto temp = it->get_npcs( [&]( const npc & guy ) {
            // Global position of NPC, in submap coordinates
            // TODO: fix point types
            const tripoint_abs_sm pos( guy.global_sm_location() );
            if( p.z() != INT_MIN && pos.z() != p.z() ) {
                return false;
            }
            return square_dist( p.xy(), pos.xy() ) <= radius;
        } );
        result.insert( result.end(), temp.begin(), temp.end() );
    }
    return result;
}

// If z == INT_MIN, allow all z-levels
std::vector<shared_ptr_fast<npc>> overmapbuffer::get_npcs_near_omt( const tripoint_abs_omt &p,
                               int radius )
{
    std::vector<shared_ptr_fast<npc>> result;
    for( auto &it : get_overmaps_near( project_to<coords::sm>( p.xy() ), radius ) ) {
        auto temp = it->get_npcs( [&]( const npc & guy ) {
            // Global position of NPC, in submap coordinates
            tripoint_abs_omt pos = guy.global_omt_location();
            if( p.z() != INT_MIN && pos.z() != p.z() ) {
                return false;
            }
            return square_dist( p.xy(), pos.xy() ) <= radius;
        } );
        result.insert( result.end(), temp.begin(), temp.end() );
    }
    return result;
}

static radio_tower_reference create_radio_tower_reference( const overmap &om, radio_tower &t,
        const tripoint_abs_sm &center )
{
    // global submap coordinates, same as center is
    const point_abs_sm pos = project_combine( om.pos(), t.pos );
    const int strength = t.strength - rl_dist( tripoint_abs_sm( pos, 0 ), center );
    return radio_tower_reference{ &t, pos, strength };
}

radio_tower_reference overmapbuffer::find_radio_station( const int frequency )
{
    // TODO: fix point types
    const tripoint_abs_sm center( get_player_character().global_sm_location() );
    for( auto &om : get_overmaps_near( center, RADIO_MAX_STRENGTH ) ) {
        for( auto &tower : om->radios ) {
            const auto rref = create_radio_tower_reference( *om, tower, center );
            if( rref.signal_strength > 0 && tower.frequency == frequency ) {
                return rref;
            }
        }
    }
    return radio_tower_reference{ nullptr, point_abs_sm(), 0 };
}

std::vector<radio_tower_reference> overmapbuffer::find_all_radio_stations()
{
    std::vector<radio_tower_reference> result;
    // TODO: fix point types
    const tripoint_abs_sm center( get_player_character().global_sm_location() );
    // perceived signal strength is distance (in submaps) - signal strength, so towers
    // further than RADIO_MAX_STRENGTH submaps away can never be received at all.
    const int radius = RADIO_MAX_STRENGTH;
    for( auto &om : get_overmaps_near( center, radius ) ) {
        for( auto &tower : om->radios ) {
            const auto rref = create_radio_tower_reference( *om, tower, center );
            if( rref.signal_strength > 0 ) {
                result.push_back( rref );
            }
        }
    }
    return result;
}

std::vector<shared_ptr_fast<npc>> overmapbuffer::get_overmap_npcs()
{
    std::vector<shared_ptr_fast<npc>> result;
    for( auto &om : overmaps ) {
        const overmap &overmap = *om.second;
        for( auto &guy : overmap.npcs ) {
            result.push_back( guy );
        }
    }
    return result;
}

std::vector<city_reference> overmapbuffer::get_cities_near( const tripoint_abs_sm &location,
        int radius )
{
    std::vector<city_reference> result;

    for( const auto om : get_overmaps_near( location, radius ) ) {
        result.reserve( result.size() + om->cities.size() );
        std::ranges::transform( om->cities, std::back_inserter( result ),
        [&]( city & element ) {
            const auto rel_pos_city = project_to<coords::sm>( element.pos );
            const auto abs_pos_city =
                tripoint_abs_sm( project_combine( om->pos(), rel_pos_city ), 0 );
            const auto distance = rl_dist( abs_pos_city, location );

            return city_reference{ &element, abs_pos_city, distance };
        } );
    }

    std::ranges::sort( result, []( const city_reference & lhs,
    const city_reference & rhs ) {
        return lhs.get_distance_from_bounds() < rhs.get_distance_from_bounds();
    } );

    return result;
}

city_reference overmapbuffer::closest_city( const tripoint_abs_sm &center )
{
    const auto cities = get_cities_near( center, omt_to_sm_copy( OMAPX ) );

    if( !cities.empty() ) {
        return cities.front();
    }

    return city_reference::invalid;
}

city_reference overmapbuffer::closest_known_city( const tripoint_abs_sm &center )
{
    const auto cities = get_cities_near( center, omt_to_sm_copy( OMAPX ) );
    const auto it = std::ranges::find_if( cities,
    [this]( const city_reference & elem ) {
        const tripoint_abs_omt p = project_to<coords::omt>( elem.abs_sm_pos );
        return seen( p );
    } );

    if( it != cities.end() ) {
        return *it;
    }

    return city_reference::invalid;
}

std::string overmapbuffer::get_description_at( const tripoint_abs_sm &where )
{
    const auto oter = ter( project_to<coords::omt>( where ) );
    const nc_color ter_color = oter->get_color();
    const std::string ter_name = colorize( oter->get_name(), ter_color );

    if( where.z() != 0 ) {
        return ter_name;
    }

    const auto closest_cref = closest_known_city( where );

    if( !closest_cref ) {
        return ter_name;
    }

    const auto &closest_city = *closest_cref.city;
    const std::string closest_city_name = colorize( closest_city.name, c_yellow );
    const direction dir = direction_from( closest_cref.abs_sm_pos, where );
    const std::string dir_name = colorize( direction_name( dir ), c_light_gray );

    const int sm_size = omt_to_sm_copy( closest_cref.city->size );
    const int sm_dist = closest_cref.distance;

    //~ First parameter is a terrain name, second parameter is a direction, and third parameter is a city name.
    std::string format_string = pgettext( "terrain description", "%1$s %2$s from %3$s" );
    if( sm_dist <= 3 * sm_size / 4 ) {
        if( sm_size >= 16 ) {
            // The city is big enough to be split in districts.
            if( sm_dist <= sm_size / 4 ) {
                //~ First parameter is a terrain name, second parameter is a direction, and third parameter is a city name.
                format_string = pgettext( "terrain description", "%1$s in central %3$s" );
            } else {
                //~ First parameter is a terrain name, second parameter is a direction, and third parameter is a city name.
                format_string = pgettext( "terrain description", "%1$s in %2$s %3$s" );
            }
        } else {
            //~ First parameter is a terrain name, second parameter is a direction, and third parameter is a city name.
            format_string = pgettext( "terrain description", "%1$s in %3$s" );
        }
    } else if( sm_dist <= sm_size ) {
        if( sm_size >= 8 ) {
            // The city is big enough to have outskirts.
            //~ First parameter is a terrain name, second parameter is a direction, and third parameter is a city name.
            format_string = pgettext( "terrain description", "%1$s on the %2$s outskirts of %3$s" );
        } else {
            //~ First parameter is a terrain name, second parameter is a direction, and third parameter is a city name.
            format_string = pgettext( "terrain description", "%1$s in %3$s" );
        }
    }

    return string_format( format_string, ter_name, dir_name, closest_city_name );
}

void overmapbuffer::spawn_monster( const tripoint_abs_sm &p )
{
    // Create a copy, so we can reuse x and y later
    point_abs_sm abs_sm = p.xy();
    point_om_sm sm;
    point_abs_om omp;
    std::tie( omp, sm ) = project_remain<coords::om>( abs_sm );
    overmap &om = get( omp );
    const tripoint_om_sm current_submap_loc( sm, p.z() );
    auto monster_bucket = om.monster_map->equal_range( current_submap_loc );
    std::for_each( monster_bucket.first, monster_bucket.second,
    [&]( std::pair<const tripoint_om_sm, monster> &monster_entry ) {
        monster &this_monster = monster_entry.second;
        // The absolute position in map squares, (x,y) is already global, but it's a
        // submap coordinate, so translate it and add the exact monster position on
        // the submap. modulo because the zombies position might be negative, as it
        // is stored *after* it has gone out of bounds during shifting. When reloading
        // we only need the part that tells where on the submap to put it.
        point ms( modulo( this_monster.posx(), SEEX ), modulo( this_monster.posy(), SEEY ) );
        assert( ms.x >= 0 && ms.x < SEEX );
        assert( ms.y >= 0 && ms.y < SEEX );
        // TODO: fix point types
        ms += project_to<coords::ms>( p.xy() ).raw();
        const map &here = get_map();
        // The monster position must be local to the main map when added to the game
        const tripoint local = tripoint( here.getlocal( ms ), p.z() );
        assert( here.inbounds( local ) );
        monster *const placed = g->place_critter_at( make_shared_fast<monster>( this_monster ),
                                local );
        if( placed ) {
            placed->on_load();
        }
    } );
    om.monster_map->erase( current_submap_loc );
}

void overmapbuffer::despawn_monster( const monster &critter )
{
    // Get absolute coordinates of the monster in map squares, translate to submap position
    // TODO: fix point types
    tripoint_abs_sm abs_sm( ms_to_sm_copy( get_map().getabs( critter.pos() ) ) );
    // Get the overmap coordinates and get the overmap, sm is now local to that overmap
    point_abs_om omp;
    tripoint_om_sm sm;
    std::tie( omp, sm ) = project_remain<coords::om>( abs_sm );
    overmap &om = get( omp );
    // Store the monster using coordinates local to the overmap.
    om.monster_map->insert( std::make_pair( sm, critter ) );
}

overmapbuffer::t_notes_vector overmapbuffer::get_notes( int z, const std::string *pattern )
{
    t_notes_vector result;
    for( auto &it : overmaps ) {
        const overmap &om = *it.second;
        const auto &all_om_notes = om.all_notes( z );
        for( const om_note &note : all_om_notes ) {
            if( pattern != nullptr && lcmatch( note.text, *pattern ) ) {
                continue;
            }
            result.emplace_back(
                project_combine( it.first, note.p ),
                note.text
            );
        }
    }
    return result;
}

overmapbuffer::t_extras_vector overmapbuffer::get_extras( int z, const std::string *pattern )
{
    overmapbuffer::t_extras_vector result;
    for( auto &it : overmaps ) {
        const overmap &om = *it.second;
        for( int i = 0; i < OMAPX; i++ ) {
            for( int j = 0; j < OMAPY; j++ ) {
                tripoint_om_omt p( i, j, z );
                const string_id<map_extra> &extra = om.extra( p );
                if( extra.is_null() ) {
                    continue;
                }
                const std::string &extra_text = extra.c_str();
                if( pattern != nullptr && lcmatch( extra_text, *pattern ) ) {
                    // pattern not found in note text
                    continue;
                }
                result.emplace_back(
                    project_combine( om.pos(), p.xy() ),
                    om.extra( p )
                );
            }
        }
    }
    return result;
}

bool overmapbuffer::is_safe( const tripoint_abs_omt &p )
{
    for( auto &mongrp : monsters_at( p ) ) {
        if( !mongrp->is_safe() ) {
            return false;
        }
    }
    return true;
}

std::optional<std::vector<tripoint_abs_omt>> overmapbuffer::place_special(
            const overmap_special &special, const tripoint_abs_omt &origin, om_direction::type dir,
            const bool must_be_unexplored, const bool force )
{
    const overmap_with_local_coords om_loc = get_om_global( origin );

    // Only place this special if we can actually place it per its criteria, or we're forcing
    // the placement, which is mostly a debug behavior, since a forced placement may not function
    // correctly (e.g. won't check correct underlying terrain).
    if( om_loc.om->can_place_special(
            special, om_loc.local, dir, must_be_unexplored ) || force ) {
        // Get the closest city that is within the overmap because
        // all of the overmap generation functions only function within
        // the single overmap. If future generation is hoisted up to the
        // buffer to spawn overmaps, then this can also be changed accordingly.
        const city c = om_loc.om->get_nearest_city( om_loc.local );
        std::vector<tripoint_abs_omt> result;
        for( const tripoint_om_omt &p : om_loc.om->place_special(
                 special, om_loc.local, dir, c, must_be_unexplored, force ) ) {
            result.push_back( project_combine( om_loc.om->pos(), p ) );
        }
        return result;
    }
    return std::nullopt;
}

bool overmapbuffer::place_special( const overmap_special_id &special_id,
                                   const tripoint_abs_omt &center,
                                   int min_radius, int max_radius )
{
    // First find the requested special. If it doesn't exist, we're done here.
    if( !special_id.is_valid() ) {
        return false;
    }
    const overmap_special &special = *special_id;
    const int longest_side = special.longest_side();

    // Get all of the overmaps within the defined radius of the center.
    for( const auto &om : get_overmaps_near(
             project_to<coords::sm>( center ), omt_to_sm_copy( max_radius ) ) ) {

        // We'll include points that within our radius. We reduce the radius by
        // the length of the longest side of our special so that we don't end up in a
        // scenario where one overmap terrain of the special is within the radius but the
        // rest of it is outside the radius (due to size, rotation, etc), which would
        // then result in us placing the special but then not finding it later if we
        // search using the same radius value we used in placing it.

        std::vector<tripoint_om_omt> points_in_range;
        const int max = std::max( 1, max_radius - longest_side );
        const int min = std::min( max, min_radius + longest_side );
        for( const tripoint_abs_omt &p : closest_points_first( center, min, max ) ) {
            point_abs_om overmap;
            tripoint_om_omt omt_within_overmap;
            std::tie( overmap, omt_within_overmap ) = project_remain<coords::om>( p );
            if( overmap == om->pos() ) {
                points_in_range.push_back( omt_within_overmap );
            }
        }

        // Attempt to place the specials using filtered points. We
        // require they be placed in unexplored terrain right now.
        if( om->place_special_custom( special, points_in_range ) > 0 ) {
            return true;
        }
    }

    // If we got this far, we've failed to make the placement.
    return false;
}

std::set<tripoint_abs_omt> overmapbuffer::electric_grid_at( const tripoint_abs_omt &p )
{
    std::set<tripoint_abs_omt> result;
    std::queue<tripoint_abs_omt> open;
    open.emplace( p );

    while( !open.empty() ) {
        // It's weired that the game takes a lot of time to copy a tripoint_abs_omt, so use reference here.
        const tripoint_abs_omt &elem = open.front();
        result.emplace( elem );
        overmap_with_local_coords omc = get_om_global( elem );
        const auto &connections_bitset = omc.om->electric_grid_connections[omc.local];
        for( size_t i = 0; i < six_cardinal_directions.size(); i++ ) {
            if( connections_bitset.test( i ) ) {
                tripoint_abs_omt other = elem + six_cardinal_directions[i];
                if( !result.contains( other ) ) {
                    open.emplace( other );
                }
            }
        }
        open.pop();
    }

    return result;
}

std::vector<tripoint_rel_omt>
overmapbuffer::electric_grid_connectivity_at( const tripoint_abs_omt &p )
{
    std::vector<tripoint_rel_omt> ret;
    ret.reserve( six_cardinal_directions.size() );

    overmap_with_local_coords omc = get_om_global( p );
    const auto &connections_bitset = omc.om->electric_grid_connections[omc.local];
    for( size_t i = 0; i < six_cardinal_directions.size(); i++ ) {
        if( connections_bitset.test( i ) ) {
            ret.emplace_back( six_cardinal_directions[i] );
        }
    }

    return ret;
}

bool overmapbuffer::add_grid_connection( const tripoint_abs_omt &lhs, const tripoint_abs_omt &rhs )
{
    if( project_to<coords::om>( lhs ).xy() != project_to<coords::om>( rhs ).xy() ) {
        debugmsg( "Connecting grids on different overmaps is not supported yet" );
        return false;
    }

    const tripoint_rel_omt coord_diff = rhs - lhs;
    if( std::abs( coord_diff.x() ) + std::abs( coord_diff.y() ) + std::abs( coord_diff.z() ) != 1 ) {
        debugmsg( "Tried to connect non-orthogonally adjacent points" );
        return false;
    }

    overmap_with_local_coords lhs_omc = get_om_global( lhs );
    overmap_with_local_coords rhs_omc = get_om_global( rhs );

    const auto lhs_iter = std::ranges::find( six_cardinal_directions,

                          coord_diff.raw() );
    const auto rhs_iter = std::ranges::find( six_cardinal_directions,

                          -coord_diff.raw() );

    size_t lhs_i = std::distance( six_cardinal_directions.begin(), lhs_iter );
    size_t rhs_i = std::distance( six_cardinal_directions.begin(), rhs_iter );

    std::bitset<six_cardinal_directions.size()> &lhs_bitset =
        lhs_omc.om->electric_grid_connections[lhs_omc.local];
    std::bitset<six_cardinal_directions.size()> &rhs_bitset =
        rhs_omc.om->electric_grid_connections[rhs_omc.local];

    if( lhs_bitset[lhs_i] && rhs_bitset[rhs_i] ) {
        debugmsg( "Tried to connect to grid two points that are connected to each other" );
        return false;
    }

    lhs_bitset[lhs_i] = true;
    rhs_bitset[rhs_i] = true;
    distribution_grid_tracker &tracker = get_distribution_grid_tracker();
    tracker.on_changed( project_to<coords::ms>( lhs ) );
    tracker.on_changed( project_to<coords::ms>( rhs ) );
    return true;
}

// TODO: Deduplicate with add_grid_connection
bool overmapbuffer::remove_grid_connection( const tripoint_abs_omt &lhs,
        const tripoint_abs_omt &rhs )
{
    const tripoint_rel_omt coord_diff = rhs - lhs;
    if( std::abs( coord_diff.x() ) + std::abs( coord_diff.y() ) + std::abs( coord_diff.z() ) != 1 ) {
        debugmsg( "Tried to disconnect non-orthogonally adjacent points" );
        return false;
    }

    overmap_with_local_coords lhs_omc = get_om_global( lhs );
    overmap_with_local_coords rhs_omc = get_om_global( rhs );

    const auto lhs_iter = std::ranges::find( six_cardinal_directions,

                          coord_diff.raw() );
    const auto rhs_iter = std::ranges::find( six_cardinal_directions,

                          -coord_diff.raw() );

    size_t lhs_i = std::distance( six_cardinal_directions.begin(), lhs_iter );
    size_t rhs_i = std::distance( six_cardinal_directions.begin(), rhs_iter );

    std::bitset<six_cardinal_directions.size()> &lhs_bitset =
        lhs_omc.om->electric_grid_connections[lhs_omc.local];
    std::bitset<six_cardinal_directions.size()> &rhs_bitset =
        rhs_omc.om->electric_grid_connections[rhs_omc.local];

    if( !lhs_bitset[lhs_i] && !rhs_bitset[rhs_i] ) {
        debugmsg( "Tried to disconnect from grid two points with no connection to each other" );
        return false;
    }

    lhs_bitset[lhs_i] = false;
    rhs_bitset[rhs_i] = false;
    distribution_grid_tracker &tracker = get_distribution_grid_tracker();
    tracker.on_changed( project_to<coords::ms>( lhs ) );
    tracker.on_changed( project_to<coords::ms>( rhs ) );
    return true;
}
