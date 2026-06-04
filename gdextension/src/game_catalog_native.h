#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class GameCatalogNative : public RefCounted {
    GDCLASS(GameCatalogNative, RefCounted)

protected:
    static void _bind_methods();

public:
    int get_max_waves() const { return 12; }
    double get_sun_radius() const { return 58.0; }
    double get_sun_damage_radius() const { return 62.0; }
    double get_enemy_spawn_padding() const { return 260.0; }
    double get_slot_angle_offset() const { return -1.57079632679489661923; }
    double get_flare_damage() const { return 95.0; }
    double get_burrower_dig_radius() const { return 74.0; }
    double get_burrower_excavation_hp() const { return 52.0; }
    double get_burrower_drain_interval() const { return 1.0; }
    double get_burrower_drain_damage() const { return 0.010; }
    double get_enemy_gravity_const() const { return 5200000.0; }
    double get_enemy_gravity_accel_cap() const { return 360.0; }
    double get_physics_projectile_gravity_const() const { return 1450000.0; }
    double get_physics_projectile_damage_ring_mult() const { return 1.15; }
    double get_physics_projectile_outward_deflect() const { return 0.12; }
    double get_physics_projectile_max_lifetime() const { return 4.0; }
    double get_physics_projectile_hit_radius() const { return 18.0; }
    int get_slingshot_cost() const { return 50; }

    Dictionary enemy_asset_paths() const;
    Dictionary enemy_animation_paths() const;
    Dictionary enemy_animation_base_angles() const;
    Dictionary enemy_masses() const;
    Dictionary tower_asset_paths() const;
    Array rings() const;
    Dictionary enemy_configs() const;
};

}
