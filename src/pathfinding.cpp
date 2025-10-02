#include "pathfinding.h"

#include <algorithm>
#include <memory>
#include <optional>
#include <queue>
#include <vector>

#include "game.h"
#include "map.h"
#include "map_iterator.h"
#include "point.h"
#include "submap.h"
#include "trap.h"
#include "veh_type.h"
#include "vehicle.h"
#include "vehicle_part.h"
#include "vpart_position.h"


#include "debug.h"
#define dbg(x) DebugLogFL((x),DC::Game)


static constexpr std::array<point, 8> DIRS_2D = {
    point_north_east,
    point_north_west,
    point_south_west,
    point_south_east,
    point_east,
    point_north,
    point_west,
    point_south,
};

decltype( Pathfinding::d_maps_store ) Pathfinding::d_maps_store = {};
decltype( Pathfinding::d_maps ) Pathfinding::d_maps = {};
decltype( Pathfinding::z_area ) Pathfinding::z_area = {};
decltype( Pathfinding::z_caches ) Pathfinding::z_caches = {};
decltype( Pathfinding::z_caches_open_air ) Pathfinding::z_caches_open_air = {};
decltype( Pathfinding::cached_closest_z_changes ) Pathfinding::cached_closest_z_changes = {};

// Thanks for nothing, MVSC
// For our MVSC builds, std::is_nan and std::is_inf are not constexpr
//   so we have to make our own
static constexpr bool is_nan( float x )
{
    return x != x;
}
static constexpr bool is_inf( float x )
{
    return x == INFINITY;
}

// PathfindingSettings impls
int PathfindingSettings::z_move_type() const
{
    int result = 0;
    result += this->can_fly ? 1 << 0 : 0;
    result += this->can_climb_stairs ? 1 << 1 : 0;
    return result;
}
// RouteSettings impls
constexpr bool RouteSettings::is_relative_search_domain() const
{
    return !( this->search_cone_angle >= 180. ||
              is_inf( this->search_radius_coeff ) );
}
constexpr bool RouteSettings::is_in_search_cone( const point start,
        const point pos,
        const point end ) const
{
    assert( 0.0 <= this->search_cone_angle );

    if( this->search_cone_angle >= 180. ) {
        return true;
    }

    // A couple special cases for boundaries
    if( start == pos || start == end ) {
        return true;
    }

    const units::angle max_cone_angle =
        units::from_degrees( this->search_cone_angle );

    const point objective_delta = end - start;
    const units::angle objective_angle =
        units::atan2( objective_delta.y, objective_delta.x );

    const point conic_delta = pos - start;
    const units::angle conic_angle = units::atan2( conic_delta.y, conic_delta.x );

    const units::angle deviation = conic_angle - objective_angle;

    return -max_cone_angle <= deviation && deviation <= max_cone_angle;
}
constexpr bool RouteSettings::is_in_search_radius( const point start,
        const point pos,
        const point end ) const
{
    if( is_inf( search_radius_coeff ) ) {
        return true;
    }

    const point midpoint = ( end + start ) / 2;

    const float objective_distance =
        rl_dist_exact( tripoint( start, 0 ), tripoint( end, 0 ) );
    const float search_radius =
        ( objective_distance * this->search_radius_coeff ) / 2;
    const float distance_to_objective =
        rl_dist_exact( tripoint( pos, 0 ), tripoint( midpoint, 0 ) );

    return distance_to_objective <= search_radius;
}
unsigned int RouteSettings::rank_weighted_rng( const unsigned int n ) const
{
    assert( -1. <= this->alpha && this->alpha <= 1. );

    // Trivial cases
    if( this->alpha >= 1. ) {
        return 0;
    }

    if( this->alpha <= -1. ) {
        return n - 1;
    }

    if( this->alpha == 0. ) {
        return rng( 0, n - 1 );
    }

    const float r = rng_float( 0.0, 1.0 );
    const float exp = ( 1. + this->alpha ) / ( 1. - this->alpha );
    const unsigned int selected_n = static_cast<unsigned int>( n * powf( r, exp ) );
    // DO NOT remove the modulo.
    // `selected_n` may sometimes be == n due to floating point stuff rounding
    // rarely causing r^exp being >= 1 if alpha is low enough
    return selected_n % n;
}
/// Pathfinding: verifications
bool Pathfinding::in_bounds( const point &p )
{
    // Specialized for pathfinding
    return this->tile_state_at( p ) != State::BOUNDS;
}
bool Pathfinding::is_in_limited_domain(
    const point &start, const point &p, const RouteSettings &route_settings )
{
    // Could be NaN if max_f_coeff = INFINITY * 0
    const float max_f = route_settings.max_f_coeff * (
                            route_settings.f_limit_based_on_max_dist ?
                            route_settings.max_dist :
                            rl_dist_exact( tripoint( start, this->z ), tripoint( this->dest, this->z ) )
                        );

    const bool is_in_f_limited_area = is_nan( max_f ) || this->get_f_unbiased( p ) <= max_f;
    const bool is_in_search_radius = route_settings.is_in_search_radius( start, p, this->dest );
    const bool is_in_search_cone = route_settings.is_in_search_cone( start, p, this->dest );

    return is_in_f_limited_area || is_in_search_radius || is_in_search_cone;
}

/// Pathfinding: map indexing
float &Pathfinding::p_at( const point &p )
{
    return this->p_map[p.y][p.x];
};
float &Pathfinding::g_at( const point &p )
{
    return this->g_map[p.y][p.x];
};
float Pathfinding::get_f_unbiased( const point &p )
{
    return this->g_at( p );
}
float Pathfinding::get_f_biased( const point &p, const point &start,
                                 float h_coeff )
{
    return this->get_f_unbiased( p ) + ( h_coeff * rl_dist_exact(
            tripoint( p, 0 ), tripoint( start, 0 ) ) );
}
Pathfinding::State &Pathfinding::tile_state_at( const point &p )
{
    return this->tile_state[p.y + 1][p.x + 1];
}
/// Pathfinding: d-map wide changes
void Pathfinding::produce_d_map( point dest, int z, PathfindingSettings settings )
{
    if( Pathfinding::d_maps_store.empty() ) {
        std::unique_ptr<Pathfinding> d_map = std::make_unique<Pathfinding>();
        Pathfinding::d_maps_store.push_back( std::move( d_map ) );
    }

    std::unique_ptr<Pathfinding> d_map = std::move( Pathfinding::d_maps_store.back() );
    Pathfinding::d_maps_store.pop_back();

    d_map->dest = dest;
    d_map->z = z;
    d_map->settings = settings;

    Pathfinding::d_maps.push_back( std::move( d_map ) );
}
void Pathfinding::clear_d_maps()
{
    for( auto &map : Pathfinding::d_maps ) {
        map->reset_maps();
        map->reset_tile_state();
        map->unbiased_frontier.clear();
        map->forbidden_moves.clear();
        map->domain = Pathfinding::MapDomain::RELATIVE_DOMAIN;
        map->is_explored = false;
        Pathfinding::d_maps_store.push_back( std::move( map ) );
    }
    Pathfinding::d_maps.clear();
    Pathfinding::cached_closest_z_changes.clear();
}
void Pathfinding::reset_maps()
{
    this->p_at( this->dest ) = 0.0;
    this->g_at( this->dest ) = 0.0;

    for( const point &p : this->map_modify_set ) {
        this->p_at( p ) = 0.0;
        this->g_at( p ) = 0.0;
    }
    this->map_modify_set.clear();
}
void Pathfinding::reset_tile_state()
{
    this->tile_state_at( this->dest ) = State::UNVISITED;

    for( const point &p : this->tile_state_modify_set ) {
        this->tile_state_at( p ) = State::UNVISITED;
    }

    this->tile_state_modify_set.clear();

    for( int y = 0; y < MAPSIZE_Y + 2; y++ ) {
        this->tile_state[y][0] = State::BOUNDS;
        this->tile_state[y][MAPSIZE_Y + 1] = State::BOUNDS;
    }
    for( int x = 0; x < MAPSIZE_X + 2; x++ ) {
        this->tile_state[0][x] = State::BOUNDS;
        this->tile_state[MAPSIZE_Y + 1][x] = State::BOUNDS;
    }
}
/// Pathfinding: Z-levels
std::unordered_map<point, Pathfinding::ZLevelChangeOpenAirPair>
&Pathfinding::get_z_cache_open_air( const int z )
{
    assert( -OVERMAP_DEPTH <= z && z <= OVERMAP_HEIGHT );

    return Pathfinding::z_caches_open_air[z + OVERMAP_DEPTH];
}
std::vector<Pathfinding::ZLevelChange> &Pathfinding::get_z_cache( const int z )
{
    assert( -OVERMAP_DEPTH <= z && z <= OVERMAP_HEIGHT );

    return Pathfinding::z_caches[z + OVERMAP_DEPTH];
}
void Pathfinding::update_z_caches( bool update_open_air )
{
    // dbg( DL::Info ) << string_format("Pathfinding_UPDATE_Z_CACHES_CALLED. update_open_air: %d", static_cast<int>(update_open_air));
    const map &here = get_map();

    point cur_z_area = here.get_abs_sub().xy();
    sm_to_ms( cur_z_area );

    if( cur_z_area == Pathfinding::z_area ) {
        return;
    }

    const point anti_shift = Pathfinding::z_area - cur_z_area;
    // This cuboid will contain negative values, it's fine
    half_open_cuboid<tripoint> prev_z_volume_local(
        tripoint( here.getlocal( Pathfinding::z_area ), -OVERMAP_DEPTH ),
        tripoint( here.getlocal( Pathfinding::z_area + point( MAPSIZE_X, MAPSIZE_Y ) ), OVERMAP_HEIGHT + 1 )
    );

    for( int z = -OVERMAP_DEPTH; z <= OVERMAP_HEIGHT; z++ ) {
        std::vector<Pathfinding::ZLevelChange> &target = Pathfinding::get_z_cache( z );

        // Shift Z-changes to match new coordinate system
        for( Pathfinding::ZLevelChange &c : target ) {
            c.from += anti_shift;
            c.to += anti_shift;
        }

        // Remove Z-level changes that have gone out of bounds into unloaded regions
        std::erase_if( target, [&here]( const auto & pair ) {
            return !( here.inbounds( pair.from ) && here.inbounds( pair.to ) );
        } );

        if( update_open_air ) {
            std::unordered_map<point, Pathfinding::ZLevelChangeOpenAirPair> &open_air_target =
                Pathfinding::get_z_cache_open_air( z );
            std::unordered_map<point, Pathfinding::ZLevelChangeOpenAirPair> new_z_cache_open_air;
            for( auto pair : open_air_target ) {
                point shifted = pair.first + anti_shift;
                // Remove open air Z-level changes that have gone out of bounds into unloaded regions
                if( !here.inbounds( shifted ) ) {
                    continue;
                }
                if( pair.second.reach_from_above.has_value() ) {
                    pair.second.reach_from_above->from += anti_shift;
                    pair.second.reach_from_above->to += anti_shift;
                }
                if( pair.second.reach_from_below.has_value() ) {
                    pair.second.reach_from_below->from += anti_shift;
                    pair.second.reach_from_below->to += anti_shift;
                }

                new_z_cache_open_air.emplace( shifted, pair.second );
            }
            open_air_target.swap( new_z_cache_open_air );
        }
    }

    // Finally, append newly loaded points
    for( int z = -OVERMAP_DEPTH; z <= OVERMAP_HEIGHT; z++ ) {
        for( const tripoint &cur : here.points_on_zlevel( z ) ) {
            if( prev_z_volume_local.contains( cur ) ) {
                continue;
            }

            const maptile &cur_tile = here.maptile_at( cur );
            const auto &cur_ter = cur_tile.get_ter_t();

            const point cur_point = cur.xy();

            if( update_open_air && cur_ter.has_flag( TFLAG_NO_FLOOR ) ) {
                // Open air
                const tripoint below_us = cur + tripoint_below;

                if( !here.inbounds_z( below_us.z ) ) {
                    continue;
                }

                if( here.impassable_ter_furn( below_us ) ) {
                    continue;
                };
                // We won't do vehicle checks for simplicity

                const ZLevelChange going_to_below = ZLevelChange{ .from = cur, .to = below_us, .type = Pathfinding::ZLevelChange::Type::OPEN_AIR };
                const ZLevelChange reach_from_below = ZLevelChange{ .from = below_us, .to = cur, .type = Pathfinding::ZLevelChange::Type::OPEN_AIR };

                // This is stored separately from other changes because it requires a different type of processing
                Pathfinding::get_z_cache_open_air( z ).emplace( cur_point, Pathfinding::ZLevelChangeOpenAirPair{ .reach_from_below = reach_from_below, .reach_from_above = std::nullopt } );

                auto &lower_level = Pathfinding::get_z_cache_open_air( z - 1 );
                if( lower_level.contains( cur_point ) ) {
                    lower_level[cur_point].reach_from_above = going_to_below;
                } else {
                    lower_level.emplace( cur_point,  Pathfinding::ZLevelChangeOpenAirPair{ .reach_from_below = std::nullopt, .reach_from_above = going_to_below } );
                }
            } else if( cur_ter.has_flag( TFLAG_GOES_UP ) ) {
                // Stair bullshitery
                const tripoint above_us = cur + tripoint_above;

                if( !here.inbounds_z( above_us.z ) ) {
                    continue;
                }

                //dbg( DL::Info ) << string_format( "Pathfinding: Found GOES_UP terrain '%s' at (%d,%d,%d), looking for GOES_DOWN above",
                 //                              cur_ter.name().c_str(), cur.x, cur.y, cur.z );

                // Try exact match first (10 tile radius for legacy compatibility)
                bool found_matching_stairs = false;
                for( const tripoint &maybe_stairs_p : closest_points_first( above_us, 10 ) ) {
                    const maptile &maybe_stairs_tile = here.maptile_at( maybe_stairs_p );
                    const auto &maybe_stair_ter = maybe_stairs_tile.get_ter_t();

                    dbg( DL::Info ) << string_format( "Pathfinding: Checking exact stair match at (%d,%d,%d): terrain '%s', has_GOES_DOWN=%d",
                                                   maybe_stairs_p.x, maybe_stairs_p.y, maybe_stairs_p.z,
                                                   maybe_stair_ter.name().c_str(),
                                                   static_cast<int>(maybe_stair_ter.has_flag( TFLAG_GOES_DOWN )) );

                    if( maybe_stair_ter.has_flag( TFLAG_GOES_DOWN ) ) {
                        const ZLevelChange stairs_up = ZLevelChange{ .from = cur, .to = maybe_stairs_p, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        const ZLevelChange stairs_down = ZLevelChange{ .from = maybe_stairs_p, .to = cur, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        Pathfinding::get_z_cache( z ).push_back( stairs_down );
                        Pathfinding::get_z_cache( z + 1 ).push_back( stairs_up );
                        
                        // dbg( DL::Info ) << string_format( "Pathfinding: Added exact STAIRS Z-changes: UP from (%d,%d,%d) to (%d,%d,%d)",
                        //                               cur.x, cur.y, cur.z, maybe_stairs_p.x, maybe_stairs_p.y, maybe_stairs_p.z );
                        found_matching_stairs = true;
                        break;
                    }
                }

                // If exact match failed, try fuzzy matching within 50 tiles
                if( !found_matching_stairs ) {
                    // dbg( DL::Info ) << string_format( "Pathfinding: Exact match failed, trying fuzzy matching for GOES_UP at (%d,%d,%d)",
                     //                              cur.x, cur.y, cur.z );
                    
                    tripoint best_match;
                    float best_distance = INFINITY;
                    
                    for( const tripoint &maybe_stairs_p : closest_points_first( tripoint( cur.x, cur.y, above_us.z ), 50 ) ) {
                        if( !here.inbounds( maybe_stairs_p ) ) {
                            continue;
                        }
                        
                        const maptile &maybe_stairs_tile = here.maptile_at( maybe_stairs_p );
                        const auto &maybe_stair_ter = maybe_stairs_tile.get_ter_t();

                        if( maybe_stair_ter.has_flag( TFLAG_GOES_DOWN ) ) {
                            const float dist = rl_dist_exact( cur, maybe_stairs_p );
                            // dbg( DL::Info ) << string_format( "Pathfinding: Found fuzzy stair match at (%d,%d,%d): terrain '%s', distance=%.2f",
                            //                               maybe_stairs_p.x, maybe_stairs_p.y, maybe_stairs_p.z,
                              //                             maybe_stair_ter.name().c_str(), dist );
                            
                            if( dist < best_distance ) {
                                best_match = maybe_stairs_p;
                                best_distance = dist;
                            }
                        }
                    }
                    
                    if( best_distance < INFINITY ) {
                        const ZLevelChange stairs_up = ZLevelChange{ .from = cur, .to = best_match, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        const ZLevelChange stairs_down = ZLevelChange{ .from = best_match, .to = cur, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        Pathfinding::get_z_cache( z ).push_back( stairs_down );
                        Pathfinding::get_z_cache( z + 1 ).push_back( stairs_up );
                        
                        // dbg( DL::Info ) << string_format( "Pathfinding: Added fuzzy STAIRS Z-changes: UP from (%d,%d,%d) to (%d,%d,%d), distance=%.2f",
                        //                               cur.x, cur.y, cur.z, best_match.x, best_match.y, best_match.z, best_distance );
                        found_matching_stairs = true;
                    }
                }
                
                if( !found_matching_stairs ) {
                    // dbg( DL::Info ) << string_format( "Pathfinding: No matching GOES_DOWN terrain found for GOES_UP at (%d,%d,%d) within 50 tiles",
                    //                               cur.x, cur.y, cur.z );
                }
            } else if( cur_ter.has_flag( TFLAG_GOES_DOWN ) ) {
                // Ditto
                const tripoint below_us = cur + tripoint_below;

                if( !here.inbounds_z( below_us.z ) ) {
                    continue;
                }

                //dbg( DL::Info ) << string_format( "Pathfinding: Found GOES_DOWN terrain '%s' at (%d,%d,%d), looking for GOES_UP below",
                //                               cur_ter.name().c_str(), cur.x, cur.y, cur.z );

                // Try exact match first (10 tile radius for legacy compatibility)
                bool found_matching_stairs = false;
                for( const tripoint &maybe_stairs_p : closest_points_first( below_us, 10 ) ) {
                    const maptile &maybe_stairs_tile = here.maptile_at( maybe_stairs_p );
                    const auto &maybe_stairs_ter = maybe_stairs_tile.get_ter_t();

                    // dbg( DL::Info ) << string_format( "Pathfinding: Checking exact stair match at (%d,%d,%d): terrain '%s', has_GOES_UP=%d",
                     //                              maybe_stairs_p.x, maybe_stairs_p.y, maybe_stairs_p.z,
                    //                               maybe_stairs_ter.name().c_str(),
                      //                             static_cast<int>(maybe_stairs_ter.has_flag( TFLAG_GOES_UP )) );

                    if( maybe_stairs_ter.has_flag( TFLAG_GOES_UP ) ) {
                        const ZLevelChange stairs_down = ZLevelChange{ .from = cur, .to = maybe_stairs_p, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        const ZLevelChange stairs_up = ZLevelChange{ .from = maybe_stairs_p, .to = cur, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        Pathfinding::get_z_cache( z ).push_back( stairs_up );
                        Pathfinding::get_z_cache( z - 1 ).push_back( stairs_down );
                        
                        // dbg( DL::Info ) << string_format( "Pathfinding: Added exact STAIRS Z-changes: DOWN from (%d,%d,%d) to (%d,%d,%d)",
                        //                               cur.x, cur.y, cur.z, maybe_stairs_p.x, maybe_stairs_p.y, maybe_stairs_p.z );
                        found_matching_stairs = true;
                        break;
                    }
                }

                // If exact match failed, try fuzzy matching within 50 tiles
                if( !found_matching_stairs ) {
                    // dbg( DL::Info ) << string_format( "Pathfinding: Exact match failed, trying fuzzy matching for GOES_DOWN at (%d,%d,%d)",
                   //                                cur.x, cur.y, cur.z );
                    
                    tripoint best_match;
                    float best_distance = INFINITY;
                    
                    for( const tripoint &maybe_stairs_p : closest_points_first( tripoint( cur.x, cur.y, below_us.z ), 50 ) ) {
                        if( !here.inbounds( maybe_stairs_p ) ) {
                            continue;
                        }
                        
                        const maptile &maybe_stairs_tile = here.maptile_at( maybe_stairs_p );
                        const auto &maybe_stairs_ter = maybe_stairs_tile.get_ter_t();

                        if( maybe_stairs_ter.has_flag( TFLAG_GOES_UP ) ) {
                            const float dist = rl_dist_exact( cur, maybe_stairs_p );
                            // dbg( DL::Info ) << string_format( "Pathfinding: Found fuzzy stair match at (%d,%d,%d): terrain '%s', distance=%.2f",
                           //                                maybe_stairs_p.x, maybe_stairs_p.y, maybe_stairs_p.z,
                           //                                maybe_stairs_ter.name().c_str(), dist );
                            
                            if( dist < best_distance ) {
                                best_match = maybe_stairs_p;
                                best_distance = dist;
                            }
                        }
                    }
                    
                    if( best_distance < INFINITY ) {
                        const ZLevelChange stairs_down = ZLevelChange{ .from = cur, .to = best_match, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        const ZLevelChange stairs_up = ZLevelChange{ .from = best_match, .to = cur, .type = Pathfinding::ZLevelChange::Type::STAIRS };
                        Pathfinding::get_z_cache( z ).push_back( stairs_up );
                        Pathfinding::get_z_cache( z - 1 ).push_back( stairs_down );
                        
                        // dbg( DL::Info ) << string_format( "Pathfinding: Added fuzzy STAIRS Z-changes: DOWN from (%d,%d,%d) to (%d,%d,%d), distance=%.2f",
                        //                               cur.x, cur.y, cur.z, best_match.x, best_match.y, best_match.z, best_distance );
                        found_matching_stairs = true;
                    }
                }
                
                if( !found_matching_stairs ) {
                    // dbg( DL::Info ) << string_format( "Pathfinding: No matching GOES_UP terrain found for GOES_DOWN at (%d,%d,%d) within 50 tiles",
                 //                                  cur.x, cur.y, cur.z );
                }
            } else if( cur_ter.has_flag( TFLAG_RAMP_UP ) ) {
                const tripoint above_us = cur + tripoint_above;

                if( !here.inbounds_z( above_us.z ) ) {
                    continue;
                }

                const ZLevelChange ramp_up = ZLevelChange{ .from = cur, .to = above_us, .type = Pathfinding::ZLevelChange::Type::RAMP };
                Pathfinding::get_z_cache( z + 1 ).push_back( ramp_up );
            } else if( cur_ter.has_flag( TFLAG_RAMP_DOWN ) ) {
                const tripoint below_us = cur + tripoint_below;

                if( !here.inbounds_z( below_us.z ) ) {
                    continue;
                }

                const ZLevelChange ramp_down = ZLevelChange{ .from = cur, .to = below_us, .type = Pathfinding::ZLevelChange::Type::RAMP };
                Pathfinding::get_z_cache( z - 1 ).push_back( ramp_down );
            } else if( cur_ter.has_flag( TFLAG_CLIMBABLE ) ) {
                // dbg(DL::Info) << string_format("Pathfinding: Evaluating CLIMBABLE terrain '%s' at (%d,%d,%d) for Z-level %d", cur_ter.name().c_str(), cur.x, cur.y, cur.z, z);

                const std::array<point, 4> cardinal_dirs = {{point_north, point_east, point_south, point_west}};
                bool found_climb_path_for_this_tile = false;
                for( const point &dir : cardinal_dirs ) {
                    const tripoint landing_spot_above = cur + dir + tripoint_above;
                    std::string dir_name = "unknown";
                    if( dir == point_north ) { dir_name = "NORTH"; }
                    else if( dir == point_east ) { dir_name = "EAST"; }
                    else if( dir == point_south ) { dir_name = "SOUTH"; }
                    else if( dir == point_west ) { dir_name = "WEST"; }

                    if( !here.inbounds( landing_spot_above ) ) {
                        // dbg( DL::Info ) << string_format("Pathfinding: CLIMBABLE '%s' at (%d,%d,%d). Adjacent spot (%d,%d,%d) to %s is out of bounds.",
                        //                                 cur_ter.name().c_str(), cur.x, cur.y, cur.z,
                        //                                 landing_spot_above.x, landing_spot_above.y, landing_spot_above.z, dir_name.c_str());
                        continue;
                    }

                    const maptile &tile_on_landing_spot = here.maptile_at( landing_spot_above );
                    const auto &landing_ter = tile_on_landing_spot.get_ter_t();

                    if( !here.impassable_ter_furn( landing_spot_above ) && !landing_ter.has_flag( TFLAG_NO_FLOOR ) ) {
                        // dbg( DL::Info ) << string_format(
                        //                               "Pathfinding: Found CLIMBABLE '%s' at (%d,%d,%d). Potential CLIMB UP via ADJACENT landing spot to %s at (%d,%d,%d) which is '%s'.",
                        //                               cur_ter.name().c_str(), cur.x, cur.y, cur.z, dir_name.c_str(),
                        //                               landing_spot_above.x, landing_spot_above.y, landing_spot_above.z, landing_ter.name().c_str() );

                        const ZLevelChange climb_up = { cur, landing_spot_above, Pathfinding::ZLevelChange::Type::CLIMB };
                        Pathfinding::get_z_cache( landing_spot_above.z ).push_back( climb_up );

                        const ZLevelChange climb_down_to_cur = { landing_spot_above, cur, Pathfinding::ZLevelChange::Type::CLIMB };
                        Pathfinding::get_z_cache( cur.z ).push_back( climb_down_to_cur );

                        // dbg( DL::Info ) << string_format(
                        //                               "Pathfinding: Added CLIMB ZChanges for ADJACENT landing to %s: UP from (%d,%d,%d) to (%d,%d,%d) and corresponding DOWN from (%d,%d,%d) to (%d,%d,%d)",
                        //                               dir_name.c_str(), cur.x, cur.y, cur.z, landing_spot_above.x, landing_spot_above.y, landing_spot_above.z,
                        //                               landing_spot_above.x, landing_spot_above.y, landing_spot_above.z, cur.x, cur.y, cur.z );
                        found_climb_path_for_this_tile = true;
                        break; // Found a valid landing spot, assume one is enough for this climbable tile.
                    } else {
                        // dbg( DL::Info ) << string_format(
                        //                               "Pathfinding: CLIMBABLE '%s' at (%d,%d,%d). Adjacent spot (%d,%d,%d) to %s ('%s') unsuitable (impassable or no_floor).",
                        //                               cur_ter.name().c_str(), cur.x, cur.y, cur.z,
                        //                               landing_spot_above.x, landing_spot_above.y, landing_spot_above.z, dir_name.c_str(), landing_ter.name().c_str() );
                    }
                }
                if (!found_climb_path_for_this_tile) {
                     // dbg( DL::Info ) << string_format("Pathfinding: CLIMBABLE '%s' at (%d,%d,%d). No suitable ADJACENT landing spots found after checking all cardinal directions.",
                    //                                 cur_ter.name().c_str(), cur.x, cur.y, cur.z);
                }
            }
        }
    }

    Pathfinding::z_area = cur_z_area;
}
/// Pathfinding: main loops
void Pathfinding::detect_culled_frontier(
    const point &start, const RouteSettings &route_settings, std::unordered_set<point> &out )
{
    std::unordered_set<point> flood_fill;
    std::vector<point> stack;

    flood_fill.insert( start );
    stack.push_back( start );

    // This is deliberately a depth-first search in order to fail quickly upon reaching map edge
    while( !stack.empty() ) {
        const point p = stack.back();
        stack.pop_back();

        for( const point &dir : DIRS_2D ) {
            const point next = p + dir;
            if( !this->in_bounds( next ) ) {
                // If we reached map edge, this means we're in an unclosed area
                return;
            }
            if( flood_fill.contains( next ) ) {
                continue;
            }
            // Visited area marks a boundary. This does include tiles outside search area, eventually.
            if( this->tile_state_at( next ) != Pathfinding::State::UNVISITED ) {
                continue;
            }
            if( !this->is_in_limited_domain( start, next, route_settings ) ) {
                // Failed domain test means we've reached a virtual boundary
                // Might as well make it INACCESSIBLE as well so we don't need to redo the check again
                this->tile_state_at( next ) = Pathfinding::State::INACCESSIBLE;
                this->tile_state_modify_set.push_back( next );
                continue;
            }
            stack.push_back( next );
            flood_fill.insert( next );
            break;
        }
    }

    // We have successfully been contained
    out = std::move( flood_fill );
}

Pathfinding::ExpansionOutcome Pathfinding::expand_2d_up_to(
    const point &start,
    const RouteSettings &route_settings )
{
    // dbg( DL::Info ) << string_format( "Pathfinding for %s: ENTERING expand_2d_up_to for z=%d, from (%d,%d) to (%d,%d)",
    //                                  this->settings.name.c_str(), this->z, start.x, start.y, this->dest.x, this->dest.y );
    using Frontier = std::priority_queue<val_pair, std::vector<val_pair>, pair_greater_cmp_first>;

    if( start == this->dest ) {
        // Special case where if we already are standing on the destination tile
        return ExpansionOutcome::PATH_FOUND;
    }

    const bool rebuild_needed = this->domain == MapDomain::ABSOLUTE_DOMAIN ?
                                // Do not rebuild only if and only if
                                //   cur domain is absolute and we are searching in absolute domain as well
                                route_settings.is_relative_search_domain() :
                                true;

    this->domain = route_settings.is_relative_search_domain() ?
                   MapDomain::RELATIVE_DOMAIN :
                   MapDomain::ABSOLUTE_DOMAIN;

    // We'll store h-coeff biased data here
    Frontier biased_frontier;

    if( !rebuild_needed ) {
        switch( this->tile_state_at( start ) ) {
            case Pathfinding::State::ACCESSIBLE:
                return ExpansionOutcome::PATH_FOUND;
            case Pathfinding::State::IMPASSABLE:
                return ExpansionOutcome::TARGET_INACCESSIBLE;
            case Pathfinding::State::INACCESSIBLE:
                return ExpansionOutcome::NO_PATH_EXISTS;
            case Pathfinding::State::UNVISITED:
                if( this->is_explored ) {
                    return ExpansionOutcome::NO_PATH_EXISTS;
                }
                for( const point &p : this->unbiased_frontier ) {
                    biased_frontier.emplace( this->get_f_biased( p, start, route_settings.h_coeff ), p );
                }
                break;
            case Pathfinding::State::BOUNDS:
                // Should not occur ever
                return ExpansionOutcome::NO_PATH_EXISTS;
        }
    } else {
        // Only reset tile state, we will reuse already calculated g-values
        this->reset_tile_state();

        biased_frontier.emplace( this->get_f_biased( this->dest, start, route_settings.h_coeff ),
                                 this->dest );
    }

    this->tile_state_at( this->dest ) = Pathfinding::State::ACCESSIBLE;
    this->p_at( this->dest ) = 0.0;
    this->g_at( this->dest ) = 0.0;
    this->unbiased_frontier.clear();

    int it = 0;

    // If this is not empty, we have encircled our target so don't bother expanding
    //   to tiles outside this area
    std::unordered_set<point> unculled_area;
    // If we happen to cull our search area, we'll store culled points here
    std::unordered_set<point> culled_frontier;
    ExpansionOutcome result = ExpansionOutcome::UNSET;

    const bool can_open_doors = !is_inf( this->settings.door_open_cost );
    const bool can_bash = this->settings.bash_strength_val > 0;
    const bool can_climb = !is_inf( this->settings.climb_cost );
    const bool care_about_mobs = this->settings.mob_presence_penalty > 0;
    const bool care_about_traps = this->settings.trap_cost > 0;
    const map &here = get_map();

    while( !biased_frontier.empty() ) {
        // Periodically check if `start` is enclosed
        //   and cull frontier if it is
        // This is useful to prevent exploring the whole map when target is inaccessible
        if( ++it % 200 == 0 ) {
            this->detect_culled_frontier( start, route_settings, unculled_area );
        }
        const point next_point = biased_frontier.top().second;

        biased_frontier.pop();

        if( !unculled_area.empty() && !unculled_area.contains( next_point ) ) {
            culled_frontier.insert( next_point );
            continue;
        }

        // These might be valid frontier points, but if they are outside of our search area, then we will not go through them this time
        if( !this->is_in_limited_domain( start, next_point, route_settings ) ) {
            // used by `detect_culled_frontier`
            this->tile_state_at( next_point ) = Pathfinding::State::INACCESSIBLE;
            this->tile_state_modify_set.push_back( next_point );
            continue;
        }

        const tripoint next_point_with_z = tripoint( next_point, this->z );

        int _;
        const vehicle *next_vehicle;
        next_vehicle = here.veh_at_internal( next_point_with_z, _ );

        for( const point &dir : DIRS_2D ) {
            // It's cur_point because we're working backwards from destination
            const point cur_point = next_point + dir;
            const tripoint cur_point_with_z = tripoint( cur_point, this->z );

            if( !this->in_bounds( cur_point ) ) {
                continue;
            }

            if( this->tile_state_at( cur_point ) != Pathfinding::State::UNVISITED ) {
                continue;
            }

            int cur_vehicle_part;
            const vehicle *cur_vehicle;
            cur_vehicle = here.veh_at_internal( cur_point_with_z, cur_vehicle_part );

            {
                bool is_move_valid = true;

                const bool is_valid_to_step_into_veh =
                    cur_vehicle == nullptr ?
                    true :
                    cur_vehicle->allowed_move( cur_vehicle->tripoint_to_mount( cur_point_with_z ),
                                               cur_vehicle->tripoint_to_mount( next_point_with_z ) );

                const bool is_valid_to_step_out_of_veh =
                    next_vehicle == nullptr ?
                    true :
                    next_vehicle->allowed_move( next_vehicle->tripoint_to_mount( cur_point_with_z ),
                                                next_vehicle->tripoint_to_mount( next_point_with_z ) );

                is_move_valid &= is_valid_to_step_into_veh;
                is_move_valid &= is_valid_to_step_out_of_veh;

                if( !is_move_valid ) {
                    this->forbidden_moves.emplace( cur_point, next_point );
                    continue;
                }
            }

            const maptile &new_tile = here.maptile_at_internal( cur_point_with_z );
            const auto &terrain = new_tile.get_ter_t();
            const auto &furniture = new_tile.get_furn_t();
            const int move_cost = here.move_cost_internal( furniture, terrain, cur_vehicle, cur_vehicle_part );

            float cur_g = this->g_at( cur_point );
            // May be false for relative search, so we'll reuse g-values there
            const bool is_g_calc_needed = cur_g == 0.0;

            if( is_g_calc_needed ) {
                bool is_diag = dir.x != 0 && dir.y != 0;
                cur_g += is_diag ? 0.75 * move_cost : 0.5 * move_cost;
                cur_g *= this->settings.move_cost_coeff;

                // First, check for trivial cost modifiers
                const bool is_rough = move_cost > 2;
                const bool is_sharp = terrain.has_flag( TFLAG_SHARP );

                cur_g += is_rough ? this->settings.rough_terrain_cost : 0.0;
                cur_g += is_sharp ? this->settings.sharp_terrain_cost : 0.0;

                if( care_about_mobs && !std::isinf( cur_g ) ) {
                    cur_g += g->critter_at( cur_point_with_z, true ) != nullptr ?
                             this->settings.mob_presence_penalty :
                             0.0;
                }

                if( care_about_traps && !std::isinf( cur_g ) ) {
                    const trap &maybe_ter_trap = terrain.trap.obj();
                    const trap &maybe_trap = maybe_ter_trap.is_benign() ? new_tile.get_trap_t() : maybe_ter_trap;
                    bool is_actual_trap = !maybe_trap.is_benign();

                    if( is_actual_trap && maybe_trap.id == trap_str_id( "tr_ledge" ) && cur_vehicle != nullptr ) {

                        is_actual_trap = false;
                    }
                    if( is_actual_trap ) {
                        cur_g += this->settings.trap_cost;
                    }
                }

                const bool is_ledge = here.has_zlevels() && terrain.has_flag( TFLAG_NO_FLOOR );
                if( is_ledge && !this->settings.can_fly ) {
                    if( cur_vehicle == nullptr ) {
                        cur_g += INFINITY;
                    }
                }

                // And finally, add a potential field extra
                if( !std::isinf( cur_g ) && this->settings.extra_g_costs.contains( cur_point ) ) {
                    cur_g += this->settings.extra_g_costs.at( cur_point );
                }

                const bool is_passable = move_cost != 0;
                float obstacle_g = 0;
                // Calculate the cost for if the tile is impassable
                while( !std::isinf( cur_g ) && !is_passable ) {
                    const bool is_climbable = terrain.has_flag( TFLAG_CLIMBABLE );
                    const bool is_door = !!terrain.open || !!furniture.open;

                    if( cur_vehicle != nullptr ) {
                        // Do processing for possible vehicle first
                        const auto vpobst = vpart_position( const_cast<vehicle &>( *cur_vehicle ),
                                                            cur_vehicle_part ).obstacle_at_part();
                        const int obstacle_part_idx = vpobst ? vpobst->part_index() : -1;

                        if( obstacle_part_idx >= 0 ) {
                            int _;
                            const bool part_is_door = cur_vehicle->part_flag( obstacle_part_idx, VPFLAG_OPENABLE );
                            const bool part_opens_from_inside = cur_vehicle->part_flag( obstacle_part_idx, "OPENCLOSE_INSIDE" );
                            const bool is_cur_point_inside = here.veh_at_internal( cur_point_with_z, _ ) == next_vehicle;
                            const bool valid_to_open = part_is_door && ( part_opens_from_inside ? is_cur_point_inside : true );

                            if( can_open_doors && valid_to_open ) {
                                obstacle_g = this->settings.door_open_cost;
                            } else if( can_bash ) {
                                const int htd = cur_vehicle->hits_to_destroy( obstacle_part_idx,
                                                this->settings.bash_strength_val * this->settings.bash_strength_quanta,
                                                DT_BASH );
                                if( htd == 0 ) {
                                    // We cannot bash down this part
                                    obstacle_g = INFINITY;
                                    break;
                                } else {
                                    obstacle_g = this->settings.bash_cost * htd;
                                    break;
                                }
                            } else {
                                // Nothing can be done here. Don't bother with other checks since vehicles take priority.
                                obstacle_g = INFINITY;
                                break;
                            }
                        }
                    }

                    if( is_climbable && can_climb ) {
                        // dbg( DL::Info ) << string_format( "Pathfinding for %s: Considering CLIMBABLE at (%d,%d,%d), setting obstacle_g = %.2f",
                        //                                  this->settings.name.c_str(),
                        //                                  cur_point.x, cur_point.y, this->z, this->settings.climb_cost );
                        obstacle_g = this->settings.climb_cost;
                        break;
                    }
                    if( is_door && can_open_doors ) {
                        // Doors that can only be open from the inside
                        const bool door_opens_from_inside = terrain.has_flag( "OPENCLOSE_INSIDE" ) ||
                                                            furniture.has_flag( "OPENCLOSE_INSIDE" );
                        const bool is_cur_point_inside = !here.is_outside( cur_point );
                        const bool valid_to_open = door_opens_from_inside ? is_cur_point_inside : true;
                        if( valid_to_open ) {
                            obstacle_g = this->settings.door_open_cost;
                            break;
                        }
                    }
                    if( can_bash ) {
                        // Time to consider bashing the obstacle
                        const int rating = here.bash_rating_internal(
                                               this->settings.bash_strength_val * this->settings.bash_strength_quanta,
                                               furniture, terrain, false, cur_vehicle, cur_vehicle_part );
                        if( rating > 1 ) {
                            obstacle_g = ( 10. / rating ) * this->settings.bash_cost;
                            break;
                        } else if( rating == 1 ) {
                            // Rating == 1 implies it will take at least 10 turns to take this down
                            //   which is a very unattractive target
                            //   so we'll penalize this target a lot
                            obstacle_g = 30.0 * this->settings.bash_cost * this->settings.bash_cost * this->settings.bash_cost;
                            break;
                        }

                    }
                    // We can do nothing anymore, close the tile
                    obstacle_g = INFINITY;
                    break;
                }

                cur_g += obstacle_g;
                // dbg( DL::Info ) << string_format( "Pathfinding for %s: at (%d,%d) after obstacle (%.2f), final cur_g is %.2f",
                //                                  this->settings.name.c_str(), cur_point.x, cur_point.y, obstacle_g, cur_g );

                this->g_at( cur_point ) = this->g_at( next_point ) + cur_g;
                this->p_at( cur_point ) = this->get_f_unbiased( next_point );

                // Reintroduce this point into frontier unless the tile is closed
                if( is_inf( cur_g ) ) {
                    this->tile_state_at( cur_point ) = Pathfinding::State::IMPASSABLE;
                } else {
                    this->tile_state_at( cur_point ) = Pathfinding::State::ACCESSIBLE;
                    biased_frontier.push( {this->get_f_biased( cur_point, start, route_settings.h_coeff ), cur_point} );
                }

                this->map_modify_set.push_back( cur_point );
                this->tile_state_modify_set.push_back( cur_point );

                if( cur_point == start ) {
                    // We have reached the target
                    if( this->tile_state_at( cur_point ) == Pathfinding::State::ACCESSIBLE ) {
                        result = ExpansionOutcome::PATH_FOUND;
                    } else {
                        result = ExpansionOutcome::TARGET_INACCESSIBLE;
                    }
                    break;
                }
            }

            if( result != ExpansionOutcome::UNSET ) {
                break;
            }
        }

        if( result != ExpansionOutcome::UNSET ) {
            break;
        }
    }

    bool is_fully_explored = !route_settings.is_relative_search_domain() && biased_frontier.empty();

    // We will be rebuilding on next search anyway if we had a relative search this time
    if( this->domain == MapDomain::ABSOLUTE_DOMAIN ) {
        while( !biased_frontier.empty() ) {
            const point p = biased_frontier.top().second;
            biased_frontier.pop();

            this->unbiased_frontier.push_back( p );
        }
        for( const point &p : culled_frontier ) {
            this->unbiased_frontier.push_back( p );
        }
    }

    if( result == ExpansionOutcome::UNSET ) {
        if( is_fully_explored ) {
            this->is_explored = true;
            return ExpansionOutcome::NO_PATH_EXISTS;
        }
        return ExpansionOutcome::PATH_NOT_FOUND;
    }

//    dbg( DL::Info ) << string_format( "Pathfinding for %s: LEAVING expand_2d_up_to, result %d",
//                                     this->settings.name.c_str(), static_cast<int>(result) );
    return result;
}


std::vector<tripoint> Pathfinding::get_route_2d(
    const point from, const point to, const int z,
    const PathfindingSettings path_settings,
    const RouteSettings route_settings )
{
    // dbg( DL::Info ) << string_format( "Pathfinding for %s: ENTERING get_route_2d for z=%d, from (%d,%d) to (%d,%d)",
    //                                  path_settings.name.c_str(), z, from.x, from.y, to.x, to.y );
    if( from == to ) {
        return std::vector<tripoint> { tripoint( from, z ), tripoint( to, z ) };
    }

    auto d_map_it = std::ranges::find_if(
                        Pathfinding::d_maps,
    [&to, &path_settings, z]( auto & map ) {
        return map->dest == to && map->z == z && map->settings == path_settings;
    } );

    Pathfinding *d_map;
    if( d_map_it == Pathfinding::d_maps.end() ) {
        Pathfinding::produce_d_map( to, z, path_settings );
        d_map = Pathfinding::d_maps.back().get();
    } else {
        d_map = d_map_it->get();
    }

    if( !d_map->is_in_limited_domain( from, from, route_settings ) ) {
        // This should only fail if max f-limit is failed
        return std::vector<tripoint>();
    }

    if( d_map->expand_2d_up_to( from, route_settings ) != ExpansionOutcome::PATH_FOUND ) {
        return std::vector<tripoint>();
    }

    const int chebyshev_distance = square_dist_fast(
                                       tripoint( from, d_map->z ),
                                       tripoint( d_map->dest, d_map->z ) );
    const float max_s = route_settings.max_s_coeff * chebyshev_distance;

    std::vector<tripoint> result;
    result.push_back( tripoint( from, d_map->z ) );

    point cur_point = from;
    float cur_cost = d_map->get_f_unbiased( cur_point );

    while( cur_point != d_map->dest ) {
        std::vector<std::pair<float, point>> candidates;
  //      dbg( DL::Info ) << string_format( "Pathfinding for %s: Reconstructing path at (%d,%d). Current cost: %.2f. Looking for neighbors with lower cost.",
  //                                       path_settings.name.c_str(), cur_point.x, cur_point.y, cur_cost );

        for( const point &dir : DIRS_2D ) {
            const point next_point = cur_point + dir;
            const bool is_in_bounds = d_map->in_bounds( next_point );
            if( !is_in_bounds ) {
                continue;
            }

            const float cost = d_map->get_f_unbiased( next_point );
            const auto state = d_map->tile_state_at( next_point );

            const bool is_accessible = state == Pathfinding::State::ACCESSIBLE;
            const bool is_not_forbidden_move = !d_map->forbidden_moves.contains( {cur_point, next_point} );

            const bool is_valid = is_accessible && is_not_forbidden_move;
            if( !is_valid ) {
                continue;
            };

            const bool already_visited = std::any_of( result.cbegin(), result.cend(),
            [&]( const tripoint & p ) {
                return p.xy() == next_point;
            } );

            if( cost <= cur_cost && !already_visited ) {
             //   dbg( DL::Info ) << string_format( "    -> Is a valid candidate." );
                candidates.emplace_back( cost, next_point );
            }
        }

        // This should not be likely to happen, but...
        if( candidates.empty() ) {
            // Maybe instead of looking at directly adjacent points,
            //   increase the radius until we find a gradient?
            result.clear();
            return result;
        }

        std::ranges::sort( candidates, []( auto & p1, auto & p2 ) {
            return p1.first < p2.first;
        } );

        const auto selected_pair = &candidates[route_settings.rank_weighted_rng( candidates.size() )];

        result.push_back( tripoint( selected_pair->second, d_map->z ) );
        cur_point = selected_pair->second;
        cur_cost = selected_pair->first;

  //      dbg( DL::Info ) << string_format( "Pathfinding for %s: pathing 2d, added (%d,%d,%d), cost %.2f",
  //                                       path_settings.name.c_str(), cur_point.x, cur_point.y, d_map->z, cur_cost );

        candidates.clear();

        // Path is too long in terms of steps taken
        if( result.size() - 2 > max_s ) {
            result.clear();
            return result;
        }
    }

    // dbg( DL::Info ) << string_format( "Pathfinding for %s: LEAVING get_route_2d, path size %d",
    //                                  path_settings.name.c_str(), result.size() );
    return result;
}

std::vector<tripoint> Pathfinding::get_route_3d(
    const tripoint from, const tripoint to,
    const PathfindingSettings path_settings,
    const RouteSettings route_settings )
{
    // dbg( DL::Info ) << string_format( "Pathfinding for %s: ENTERING get_route_3d from (%d,%d,%d) to (%d,%d,%d)",
    //                                  path_settings.name.c_str(), from.x, from.y, from.z, to.x, to.y, to.z );
    // dbg( DL::Info ) << string_format("Pathfinding_GET_ROUTE_3D_CALLED_INTERNALLY from (%d,%d,%d) to (%d,%d,%d)", from.x, from.y, from.z, to.x, to.y, to.z);
    // We won't bother with complicated Z-level paths because that vastly, vastly increases the pathfinding cost
    // Instead, we will **only** consider taking z_changes that bring us closer to target's Z level.
    const bool we_go_up = to.z > from.z;

    Pathfinding::update_z_caches( path_settings.can_fly );

    // Determine our Z-path
    std::vector<ZLevelChange> z_path;
    {
        tripoint cur_origin = to;
        point cur_origin_point = to.xy();

        while( cur_origin.z != from.z ) {
            Pathfinding::ZLevelChange best_z_change;
            std::tuple<bool, int, tripoint> cache_pair{ we_go_up, path_settings.z_move_type(), cur_origin };

            if( Pathfinding::cached_closest_z_changes.contains( cache_pair ) ) {
                best_z_change = Pathfinding::cached_closest_z_changes.at( cache_pair );
            } else {
                std::vector<Pathfinding::ZLevelChange> candidates;

                for( const Pathfinding::ZLevelChange &z_change : Pathfinding::get_z_cache( cur_origin.z ) ) {
                    bool can_be_taken = true;
                    const char* type_name = "UNKNOWN";
                    switch( z_change.type ) {
                        case Pathfinding::ZLevelChange::Type::STAIRS:
                            type_name = "STAIRS";
                            can_be_taken &= path_settings.can_climb_stairs || path_settings.can_fly;
                            break;
                        case Pathfinding::ZLevelChange::Type::OPEN_AIR:
                            type_name = "OPEN_AIR";
                            // Open air is processed separately
                            continue;
                        case Pathfinding::ZLevelChange::Type::RAMP:
                            type_name = "RAMP";
                            // Ramps can be taken by all creatures currently
                            break;
                        case Pathfinding::ZLevelChange::Type::CLIMB:
                            type_name = "CLIMB";
                            can_be_taken &= ( !is_inf( path_settings.climb_cost ) || path_settings.can_fly );
                            break;
                    }

                    const bool does_not_overshoot = we_go_up ?
                                                    z_change.from.z >= from.z :
                                                    z_change.from.z <= from.z;
                    const bool leads_closer_to_from = we_go_up ?
                                                      z_change.from.z < cur_origin.z :
                                                      z_change.from.z > cur_origin.z;

                    // dbg( DL::Info ) << string_format( "Pathfinding: Evaluating Z-change (%d,%d,%d)->(%d,%d,%d) type=%s, can_be_taken=%d, overshoot=%d, closer=%d",
                     //                              z_change.from.x, z_change.from.y, z_change.from.z,
                     //                              z_change.to.x, z_change.to.y, z_change.to.z,
                     //                              type_name, static_cast<int>(can_be_taken),
                     //                              static_cast<int>(does_not_overshoot), static_cast<int>(leads_closer_to_from) );

                    if( can_be_taken && does_not_overshoot && leads_closer_to_from ) {
                        candidates.push_back( z_change );
                        // dbg( DL::Info ) << string_format( "Pathfinding: Added Z-change candidate (%d,%d,%d)->(%d,%d,%d) type=%s",
                       //                                z_change.from.x, z_change.from.y, z_change.from.z,
                         //                              z_change.to.x, z_change.to.y, z_change.to.z, type_name );
                    }
                }

                // Prioritize stairs over climbing for normal movement
                std::vector<Pathfinding::ZLevelChange> stair_candidates;
                std::vector<Pathfinding::ZLevelChange> other_candidates;
                for( const auto &cand : candidates ) {
                    if( cand.type == Pathfinding::ZLevelChange::Type::STAIRS ) {
                        stair_candidates.push_back( cand );
                    } else {
                        other_candidates.push_back( cand );
                    }
                }
                
                // Use stairs if available, otherwise fall back to other methods
                if( !stair_candidates.empty() ) {
                    candidates = stair_candidates;
                    // dbg( DL::Info ) << string_format( "Pathfinding: Prioritizing %d sta candidates over %d other candidates",
                    //                               stair_candidates.size(), other_candidates.size() );
                } else {
                    // dbg( DL::Info ) << string_format( "Pathfinding: No stair candidates found, using %d other candidates", other_candidates.size() );
                }

                // Now, find the best next Z level
                int best_next_z_level = to.z;
                for( const Pathfinding::ZLevelChange &z_change : candidates ) {
                    if( we_go_up ) {
                        best_next_z_level = std::min( z_change.from.z, best_next_z_level );
                    } else {
                        best_next_z_level = std::max( z_change.from.z, best_next_z_level );
                    }
                }

                float best_distance = INFINITY;
                for( const auto &z_change : candidates ) {
                    if( z_change.from.z != best_next_z_level ) {
                        continue;
                    }
                    const float dist = rl_dist_exact( cur_origin, z_change.to );
                    if( dist < best_distance ) {
                        best_z_change = z_change;
                        best_distance = dist;
                    }
                }

                const char* selected_type_name = "UNKNOWN";
                switch( best_z_change.type ) {
                    case Pathfinding::ZLevelChange::Type::STAIRS: selected_type_name = "STAIRS"; break;
                    case Pathfinding::ZLevelChange::Type::OPEN_AIR: selected_type_name = "OPEN_AIR"; break;
                    case Pathfinding::ZLevelChange::Type::RAMP: selected_type_name = "RAMP"; break;
                    case Pathfinding::ZLevelChange::Type::CLIMB: selected_type_name = "CLIMB"; break;
                }

                // dbg( DL::Info ) << string_format( "Pathfinding: Selected Z-change (%d,%d,%d)->(%d,%d,%d) type=%s",
                //                               best_z_change.from.x, best_z_change.from.y, best_z_change.from.z,
                //                               best_z_change.to.x, best_z_change.to.y, best_z_change.to.z,
                //                               selected_type_name );

                const map &here = get_map();
                const maptile &from_tile = here.maptile_at( best_z_change.from );
                const maptile &to_tile = here.maptile_at( best_z_change.to );
                
                // dbg( DL::Info ) << string_format( "Pathfinding: Z-change details - Origin: (%d,%d,%d), From tile: '%s', To tile: '%s'",
                 //                              cur_origin.x, cur_origin.y, cur_origin.z,
                 //                              from_tile.get_ter_t().name().c_str(),
                //                               to_tile.get_ter_t().name().c_str() );

                // Open air processing
                if( path_settings.can_fly ) {
                    std::unordered_map<point, ZLevelChangeOpenAirPair> &target =
                        Pathfinding::get_z_cache_open_air( cur_origin.z );

                    // There's a rare case where no valid non-open-air way exists to this Z-level
                    //   in which case `closest_points_first` would return a INT_MAX radius of points
                    //   causing an oopsie
                    // If that's the case, we have to iterate over open airs directly instead
                    std::vector<point> source;
                    const bool source_is_closest_points = !std::isinf( best_distance );
                    if( source_is_closest_points ) {
                        source = closest_points_first( cur_origin_point, static_cast<int>( best_distance ) );
                    } else {
                        for( const auto &pair : target ) {
                            source.push_back( pair.first );
                        }
                    }

                    for( const point &p : source ) {
                        // Are we considering open airs that are already beyond our best known move?
                        //   only valid for closest_point movement since they're ordered
                        if( source_is_closest_points && square_dist( cur_origin_point, p ) > best_distance ) {
                            break;
                        }
                        if( source_is_closest_points && !target.contains( p ) ) {
                            continue;
                        }
                        Pathfinding::ZLevelChangeOpenAirPair z_pair = target[p];
                        if( we_go_up && z_pair.reach_from_below.has_value() ) {
                            const float dist = rl_dist_exact( tripoint( cur_origin_point, 0 ), tripoint( p, 0 ) );
                            if( dist < best_distance ) {
                                best_z_change = *z_pair.reach_from_below;
                                best_distance = dist;
                            }
                        } else if( !we_go_up && z_pair.reach_from_above.has_value() ) {
                            const float dist = rl_dist_exact( tripoint( cur_origin_point, 0 ), tripoint( p, 0 ) );
                            if( dist < best_distance ) {
                                best_z_change = *z_pair.reach_from_above;
                                best_distance = dist;
                            }
                        }
                    }
                }

                if( is_inf( best_distance ) ) {
                    // dbg( DL::Info ) << "Pathfinding: No viable Z-change found. Aborting route.";
                    // No trivial Z path exists, give up
                    return std::vector<tripoint>();
                }

                Pathfinding::cached_closest_z_changes.insert_or_assign( cache_pair, best_z_change );
            }

            z_path.push_back( best_z_change );
            cur_origin = best_z_change.from;
        }
    }

    std::unordered_set<tripoint> ramp_excluded;
    std::vector<tripoint> result;
    // Now try to construct path
    {
        point cur_pos = from.xy();
        while( !z_path.empty() ) {
            const Pathfinding::ZLevelChange next = z_path.back();

            const std::vector<tripoint> path_segment = Pathfinding::get_route_2d(
                        cur_pos, next.from.xy(), next.from.z,
                        path_settings, route_settings );
            if( path_segment.empty() ) {
                // dbg( DL::Info ) << string_format( "Pathfinding: Failed to path to Z-change at (%d,%d,%d). Aborting.",
                //                                  next.from.x, next.from.y, next.from.z );
                // Give up early based on our inability to path to that z-change
                result.clear();
                return result;
            }

            result.insert( result.end(), path_segment.begin(), path_segment.end() );
            // Ramps are special in that we do not step on the last tile unless we're flying
            const bool is_ramp_like = !path_settings.can_fly &&
                                      next.type == Pathfinding::ZLevelChange::Type::RAMP;
            if( is_ramp_like ) {
                ramp_excluded.insert( next.from );
            }
            cur_pos = next.to.xy();
            z_path.pop_back();
        }

        // We arrived to final Z level
        const std::vector<tripoint> final_segment = Pathfinding::get_route_2d(
                    cur_pos, to.xy(), to.z,
                    path_settings, route_settings );
        if( final_segment.empty() ) {
            result.clear();
            return result;
        }
        result.insert( result.end(), final_segment.begin(), final_segment.end() );

        // Finally, remove ramp tiles
        std::erase_if( result, [&ramp_excluded]( const tripoint & p ) {
            return ramp_excluded.contains( p );
        } );
    }
    // dbg( DL::Info ) << string_format( "Pathfinding for %s: LEAVING get_route_3d, path size %d",
    //                                  path_settings.name.c_str(), result.size() );
    return result;
}

std::vector<tripoint> Pathfinding::route(
    tripoint from, tripoint to,
    const std::optional<PathfindingSettings> maybe_path_settings,
    const std::optional<RouteSettings> maybe_route_settings )
{
    // dbg( DL::Info ) << "Pathfinding_ROUTE_ENTERED. FromX: " << from.x << " FromY: " << from.y << " FromZ: " << from.z << " ToX: " << to.x << " ToY: " << to.y << " ToZ: " << to.z;
    const map &here = get_map();

    here.clip_to_bounds( from );
    here.clip_to_bounds( to );

    // dbg( DL::Info ) << string_format("Pathfinding_ROUTE: After clip, from.z=%d, to.z=%d", from.z, to.z);

    PathfindingSettings path_settings = maybe_path_settings.has_value() ? *maybe_path_settings : PathfindingSettings();
    RouteSettings route_settings = maybe_route_settings.has_value() ? *maybe_route_settings : RouteSettings();

    if( rl_dist_exact( from, to ) > route_settings.max_dist ) {
        // dbg( DL::Info ) << string_format("Pathfinding_ROUTE: Exiting due to max_dist. from=(%d,%d,%d), to=(%d,%d,%d), max_dist=%.2f", from.x, from.y, from.z, to.x, to.y, to.z, route_settings.max_dist);
        return std::vector<tripoint>();
    }

    // dbg( DL::Info ) << string_format("Pathfinding_ROUTE: Evaluating from.z (%d) == to.z (%d)", from.z, to.z);
    if( from.z == to.z ) {
        // dbg( DL::Info ) << string_format("Pathfinding_ROUTE: Calling get_route_2d for z=%d", from.z);
        return Pathfinding::get_route_2d( from.xy(), to.xy(), from.z,
                                          path_settings, route_settings );
    }
    // dbg( DL::Info ) << string_format("Pathfinding_ROUTE: Calling get_route_3d for from.z=%d to to.z=%d", from.z, to.z);
    return Pathfinding::get_route_3d( from, to, path_settings, route_settings );
};

void Pathfinding::mark_dirty_z_cache()
{
    // dbg( DL::Info ) << "Pathfinding: Marking Z-caches as dirty.";
    Pathfinding::cached_closest_z_changes.clear();

    Pathfinding::z_area = point( -9999, -9999 );
}
