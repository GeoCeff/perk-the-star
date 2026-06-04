#pragma once
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <cmath>

namespace godot {

static constexpr double ORBITAL_TOWER_PI = 3.14159265358979323846;

class OrbitalTower : public Node2D {
    GDCLASS(OrbitalTower, Node2D)

protected:
    static void _bind_methods();

private:
    double  m_angle;
    double  m_angular_velocity;
    double  m_ring_radius;
    double  m_engagement_arc;
    Vector2 m_sun_pos;

    String  m_tower_type;
    double  m_damage;
    double  m_fire_rate;
    double  m_fire_timer;
    double  m_slow_amount;
    int     m_chain_count;
    int     m_upgrade_level;

    int     m_analyzed_variant;
    double  m_bio_multiplier;
    double  m_bio_timer;

    double  m_cooldown_timer;

    bool    m_slingshot_mode;
    double  m_slingshot_charge;

public:
    OrbitalTower();
    ~OrbitalTower();

    void _process(double delta) override;

    void setup(const String& tower_type, int ring_idx,
               double start_angle, double radius, double period);
    void upgrade();

    bool   is_in_arc(const Vector2& enemy_global_pos) const;
    void   try_fire();

    String  get_tower_type()        const { return m_tower_type; }
    double  get_angle()             const { return m_angle; }
    double  get_angular_velocity()  const { return m_angular_velocity; }
    double  get_ring_radius()       const { return m_ring_radius; }
    double  get_damage()            const { return m_damage; }
    double  get_engagement_arc_deg() const { return m_engagement_arc * (180.0 / ORBITAL_TOWER_PI); }
    Vector2 get_sun_pos()           const { return m_sun_pos; }
    int     get_upgrade_level()     const { return m_upgrade_level; }
    bool    get_slingshot_ready()   const { return m_slingshot_charge >= 1.0; }
    Vector2 compute_physics_launch_velocity(const Vector2& target_pos, double base_speed) const;

    void set_tower_type(const String& v)  { m_tower_type = v; }
    void set_sun_pos(const Vector2& v)    { m_sun_pos = v; }
    void set_angle(double v)              { m_angle = v; }
    void set_bio_analyzed(int variant_id) { m_analyzed_variant = variant_id; m_bio_multiplier = 3.0; }
    void set_slingshot_mode(bool value)   { m_slingshot_mode = value; }
};

}
