#pragma once
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <cmath>

namespace godot {

class OrbitalTower : public Node2D {
    GDCLASS(OrbitalTower, Node2D)

protected:
    static void _bind_methods();

private:
    // Orbital state
    double  m_angle;             // current angular position (radians)
    double  m_angular_velocity;  // radians/sec  (ω = 2π/T)
    double  m_ring_radius;       // pixels
    double  m_engagement_arc;    // radians (half-arc each side)
    Vector2 m_sun_pos;

    // Combat stats
    String  m_tower_type;
    double  m_damage;
    double  m_fire_rate;         // shots/second (0 = manual/special)
    double  m_fire_timer;
    double  m_slow_amount;       // 0.0 = no slow
    int     m_chain_count;
    int     m_upgrade_level;

    // Bio-Lab state
    int     m_analyzed_variant;  // -1 = not analyzed
    double  m_bio_multiplier;
    double  m_bio_timer;

    // Magnetic Net state
    double  m_cooldown_timer;

public:
    OrbitalTower();
    ~OrbitalTower();

    void _process(double delta) override;

    // Setup
    void setup(const String& tower_type, int ring_idx,
               double start_angle, double radius, double period);
    void upgrade();

    // Core methods
    bool   is_in_arc(const Vector2& enemy_global_pos) const;
    void   try_fire();

    // Getters
    String  get_tower_type()        const { return m_tower_type; }
    double  get_angle()             const { return m_angle; }
    double  get_angular_velocity()  const { return m_angular_velocity; }
    double  get_ring_radius()       const { return m_ring_radius; }
    double  get_damage()            const { return m_damage; }
    double  get_engagement_arc_deg() const { return m_engagement_arc * (180.0 / M_PI); }
    Vector2 get_sun_pos()           const { return m_sun_pos; }
    int     get_upgrade_level()     const { return m_upgrade_level; }

    // Setters
    void set_tower_type(const String& v)  { m_tower_type = v; }
    void set_sun_pos(const Vector2& v)    { m_sun_pos = v; }
    void set_angle(double v)              { m_angle = v; }
    void set_bio_analyzed(int variant_id) { m_analyzed_variant = variant_id; m_bio_multiplier = 3.0; }
};

} 