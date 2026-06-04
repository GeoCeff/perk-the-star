#pragma once

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class Astrophage : public Node2D {
    GDCLASS(Astrophage, Node2D)

public:
    enum EnemyVariant {
        DRIFTER,
        BLOOM,
        BURROWER,
        MIMIC,
        FARMER,
        PRIME,
    };

private:
    int     m_variant;
    double  m_hp;
    double  m_max_hp;
    double  m_speed;
    double  m_speed_modifier;
    double  m_corona_damage;
    bool    m_is_burrowing;
    bool    m_is_cloaked;
    bool    m_is_clustered;
    int     m_reward_credits;
    Vector2 m_sun_position;
    double  m_wiggle_offset;
    int     m_prime_phase;
    double  m_mass;
    double  m_velocity_x;
    double  m_velocity_y;
    double  m_max_speed;
    bool    m_use_gravity;
    double  m_frenzy_timer;
    bool    m_is_spawning_frenzy;

protected:
    static void _bind_methods();

public:
    Astrophage();
    ~Astrophage();

    void _process(double delta) override;

    void setup(int variant, const Vector2& spawn_pos, const Vector2& sun_pos);
    void take_hit(double damage, const String& source);
    void apply_slow(double slow_factor);
    void set_clustered(bool value);

    int     get_variant() const { return m_variant; }
    double  get_hp() const { return m_hp; }
    double  get_max_hp() const { return m_max_hp; }
    bool    get_is_cloaked() const { return m_is_cloaked; }
    bool    get_is_burrowing() const { return m_is_burrowing; }
    double  get_corona_damage() const { return m_corona_damage; }
    int     get_reward() const { return m_reward_credits; }
    Vector2 get_sun_position() const { return m_sun_position; }
    void    set_sun_position(const Vector2& value) { m_sun_position = value; }

private:
    void _on_defeated();
    void _share_cluster_damage(double damage);
};

}

VARIANT_ENUM_CAST(godot::Astrophage::EnemyVariant);
