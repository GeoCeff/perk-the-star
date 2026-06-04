#include "orbital_tower.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/core/property_info.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void OrbitalTower::_bind_methods() {
    ClassDB::bind_method(D_METHOD("setup", "tower_type", "ring_idx",
        "start_angle", "radius", "period"), &OrbitalTower::setup);
    ClassDB::bind_method(D_METHOD("upgrade"),     &OrbitalTower::upgrade);
    ClassDB::bind_method(D_METHOD("is_in_arc", "enemy_global_pos"), &OrbitalTower::is_in_arc);
    ClassDB::bind_method(D_METHOD("try_fire"),    &OrbitalTower::try_fire);

    ClassDB::bind_method(D_METHOD("get_tower_type"),         &OrbitalTower::get_tower_type);
    ClassDB::bind_method(D_METHOD("set_tower_type", "v"),    &OrbitalTower::set_tower_type);
    ClassDB::bind_method(D_METHOD("get_sun_pos"),            &OrbitalTower::get_sun_pos);
    ClassDB::bind_method(D_METHOD("set_sun_pos", "v"),       &OrbitalTower::set_sun_pos);
    ClassDB::bind_method(D_METHOD("get_angle"),              &OrbitalTower::get_angle);
    ClassDB::bind_method(D_METHOD("set_angle", "v"),         &OrbitalTower::set_angle);
    ClassDB::bind_method(D_METHOD("get_damage"),             &OrbitalTower::get_damage);
    ClassDB::bind_method(D_METHOD("get_upgrade_level"),      &OrbitalTower::get_upgrade_level);
    ClassDB::bind_method(D_METHOD("get_engagement_arc_deg"), &OrbitalTower::get_engagement_arc_deg);
    ClassDB::bind_method(D_METHOD("set_bio_analyzed", "id"), &OrbitalTower::set_bio_analyzed);
    ClassDB::bind_method(D_METHOD("get_slingshot_ready"), &OrbitalTower::get_slingshot_ready);
    ClassDB::bind_method(D_METHOD("set_slingshot_mode", "value"), &OrbitalTower::set_slingshot_mode);
    ClassDB::bind_method(D_METHOD("compute_physics_launch_velocity", "target_pos", "base_speed"), &OrbitalTower::compute_physics_launch_velocity);

    ADD_SIGNAL(MethodInfo("fire_at_target",
        PropertyInfo(Variant::OBJECT, "target_node"),
        PropertyInfo(Variant::FLOAT,  "damage"),
        PropertyInfo(Variant::STRING, "tower_type"),
        PropertyInfo(Variant::INT,    "chain_count")));
    ADD_SIGNAL(MethodInfo("try_fire"));

    ADD_PROPERTY(PropertyInfo(Variant::STRING,  "tower_type"), "set_tower_type", "get_tower_type");
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "sun_pos"),    "set_sun_pos",    "get_sun_pos");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT,   "angle"),      "set_angle",      "get_angle");
}

OrbitalTower::OrbitalTower()
    : m_angle(0.0), m_angular_velocity(0.0), m_ring_radius(80.0),
      m_engagement_arc(ORBITAL_TOWER_PI / 6.0),
      m_sun_pos(Vector2(640, 360)),
      m_tower_type("photon_splitter"),
      m_damage(10.0), m_fire_rate(0.3), m_fire_timer(0.0),
      m_slow_amount(0.0), m_chain_count(0), m_upgrade_level(1),
      m_analyzed_variant(-1), m_bio_multiplier(1.0), m_bio_timer(0.0),
      m_cooldown_timer(0.0), m_slingshot_mode(false), m_slingshot_charge(1.0)
{}

OrbitalTower::~OrbitalTower() {}

void OrbitalTower::setup(const String& tower_type, int /*ring_idx*/,
                          double start_angle, double radius, double period)
{
    m_tower_type       = tower_type;
    m_angle            = start_angle;
    m_ring_radius      = radius;
    m_angular_velocity = (2.0 * ORBITAL_TOWER_PI) / period;

    // Per-type stats
    if      (tower_type == "photon_splitter") { m_damage=10; m_fire_rate=0.3; m_slow_amount=0.0; m_chain_count=0; }
    else if (tower_type == "cryo_probe")      { m_damage=0;  m_fire_rate=1.0; m_slow_amount=0.4; m_chain_count=0; }
    else if (tower_type == "bio_lab")         { m_damage=5;  m_fire_rate=0.5; m_slow_amount=0.0; m_chain_count=0; m_bio_multiplier=1.0; }
    else if (tower_type == "magnetic_net")    { m_damage=0;  m_fire_rate=0.0; m_slow_amount=0.0; m_chain_count=0; }
    else if (tower_type == "helios_cannon")   { m_damage=80; m_fire_rate=0.0; m_slow_amount=0.0; m_chain_count=0; }
    else if (tower_type == "tardigrade_bomb") { m_damage=15; m_fire_rate=0.8; m_slow_amount=0.0; m_chain_count=5; }
}

void OrbitalTower::_process(double delta) {
    // ── Orbital motion ──
    m_angle = std::fmod(m_angle + m_angular_velocity * delta, 2.0 * ORBITAL_TOWER_PI);
    double px = m_sun_pos.x + m_ring_radius * std::cos(m_angle);
    double py = m_sun_pos.y + m_ring_radius * std::sin(m_angle);
    set_position(Vector2(static_cast<float>(px), static_cast<float>(py)));
    set_rotation(static_cast<float>(m_angle + ORBITAL_TOWER_PI / 2.0));

    // ── Cooldown ──
    if (m_cooldown_timer > 0) m_cooldown_timer -= delta;

    // ── Fire ──
    if (m_fire_rate > 0.0) {
        m_fire_timer -= delta;
        if (m_fire_timer <= 0.0) {
            m_fire_timer = 1.0 / m_fire_rate;
            try_fire();
        }
    }
}

bool OrbitalTower::is_in_arc(const Vector2& enemy_pos) const {
    Vector2 to_enemy = enemy_pos - get_global_position();
    double enemy_angle = std::atan2(to_enemy.y, to_enemy.x);
    double diff = std::fmod(enemy_angle - m_angle + 4.0 * ORBITAL_TOWER_PI, 2.0 * ORBITAL_TOWER_PI);
    if (diff > ORBITAL_TOWER_PI) diff -= 2.0 * ORBITAL_TOWER_PI;
    return std::abs(diff) <= m_engagement_arc;
}

void OrbitalTower::try_fire() {
    // Emit signal — GDScript handles finding the actual target node
    // This keeps C++ clean and lets GDScript manage the node tree
    emit_signal("try_fire");
}

Vector2 OrbitalTower::compute_physics_launch_velocity(const Vector2& target_pos, double base_speed) const {
    Vector2 to_target = target_pos - get_global_position();
    if (to_target.length_squared() <= 0.0001f) {
        to_target = m_sun_pos - get_global_position();
    }
    to_target = to_target.normalized();

    Vector2 tangent(
        static_cast<float>(-std::sin(m_angle)),
        static_cast<float>( std::cos(m_angle))
    );
    double orbital_contribution = m_angular_velocity * m_ring_radius * 0.6;
    return to_target * static_cast<float>(base_speed)
         + tangent * static_cast<float>(orbital_contribution);
}

void OrbitalTower::upgrade() {
    m_upgrade_level++;
    m_damage    *= 1.5;
    if (m_fire_rate > 0) m_fire_rate *= 1.2;
}
