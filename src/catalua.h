#pragma once

#include "type_id.h"
#include "mattack_common.h"
#include "catalua_sol.h"
#include <memory>
#include <filesystem>

class Item_factory;
class map;
class time_point;
struct tripoint;
class world;
class monster;

namespace cata
{
struct lua_state;
struct lua_state_deleter {
    void operator()( lua_state *state ) const;
};

bool has_lua();
int get_lua_api_version();
std::string get_lapi_version_string();
void startup_lua_test();
bool generate_lua_docs( const std::filesystem::path &path );
void show_lua_console();
void reload_lua_code();
void debug_write_lua_backtrace( std::ostream &out );

bool save_world_lua_state( const world *world, const std::string &path );
bool load_world_lua_state( const world *world, const std::string &path );

std::unique_ptr<lua_state, lua_state_deleter> make_wrapped_state();

void init_global_state_tables( lua_state &state, const std::vector<mod_id> &modlist );
void set_mod_being_loaded( lua_state &state, const mod_id &mod );
void clear_mod_being_loaded( lua_state &state );
void run_mod_preload_script( lua_state &state, const mod_id &mod );
void run_mod_finalize_script( lua_state &state, const mod_id &mod );
void run_mod_main_script( lua_state &state, const mod_id &mod );
void run_on_game_load_hooks( lua_state &state );
void run_on_game_save_hooks( lua_state &state );
void run_on_every_x_hooks( lua_state &state );
void run_on_mapgen_postprocess_hooks( lua_state &state, map &m, const tripoint &p,
                                      const time_point &when );
void reg_lua_iuse_actors( lua_state &state, Item_factory &ifactory );
void register_monattack(sol::state& lua);

class lua_mattack_wrapper : public mattack_actor
{
private:
    sol::protected_function lua_function;

public:
    lua_mattack_wrapper(const mattack_id& id, sol::protected_function func);
    ~lua_mattack_wrapper() override;

    bool call(monster& m) const override;
    std::unique_ptr<mattack_actor> clone() const override;
    void load_internal(const JsonObject& jo, const std::string& src) override;
};
} // namespace cata


