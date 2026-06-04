#include "astrophage.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <algorithm>
#include <cmath>

using namespace godot;

void Astrophage::_bind_methods() {
    ClassDB::bind_method(D_METHOD("setup","variant","spawn_pos","sun_pos"), &Astrophage::setup);
    ClassDB::bind_method(D_METHOD("take_hit","damage","source"), &Astrophage::take_hit);
    ClassDB::bind_method(D_METHOD("apply_slow","factor"), &Astrophage::apply_slow);
    ClassDB::bind_method(D_METHOD("set_clustered","v"), &Astrophage::set_clustered);
    ClassDB::bind_method(D_METHOD("get_variant"),     &Astrophage::get_variant);
    ClassDB::bind_method(D_METHOD("get_hp"),          &Astrophage::get_hp);
    ClassDB::bind_method(D_METHOD("get_max_hp"),      &Astrophage::get_max_hp);
    ClassDB::bind_method(D_METHOD("get_is_cloaked"),  &Astrophage::get_is_cloaked);
    ClassDB::bind_method(D_METHOD("get_is_burrowing"),&Astrophage::get_is_burrowing);
    ClassDB::bind_method(D_METHOD("get_corona_damage"),&Astrophage::get_corona_damage);
    ClassDB::bind_method(D_METHOD("get_reward"),      &Astrophage::get_reward);
    ClassDB::bind_method(D_METHOD("get_sun_position"),&Astrophage::get_sun_position);
    ClassDB::bind_method(D_METHOD("set_sun_position","v"),&Astrophage::set_sun_position);

    ADD_SIGNAL(MethodInfo("defeated",
        PropertyInfo(Variant::INT, "reward_credits")));
    ADD_SIGNAL(MethodInfo("reached_corona"));
    ADD_SIGNAL(MethodInfo("bloom_split",
        PropertyInfo(Variant::VECTOR2, "position")));
    ADD_SIGNAL(MethodInfo("cluster_damage_request",
        PropertyInfo(Variant::FLOAT, "damage")));

    BIND_ENUM_CONSTANT(DRIFTER);
    BIND_ENUM_CONSTANT(BLOOM);
    BIND_ENUM_CONSTANT(BURROWER);
    BIND_ENUM_CONSTANT(MIMIC);
    BIND_ENUM_CONSTANT(FARMER);
    BIND_ENUM_CONSTANT(PRIME);

    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2,"sun_position"),
        "set_sun_position","get_sun_position");
}

Astrophage::Astrophage()
    : m_variant(DRIFTER), m_hp(30), m_max_hp(30),
      m_speed(60), m_speed_modifier(1.0), m_corona_damage(0.05),
      m_is_burrowing(false), m_is_cloaked(false), m_is_clustered(false),
      m_reward_credits(5), m_sun_position(Vector2(640,360)),
      m_wiggle_offset(0), m_prime_phase(0),
      m_mass(1.0), m_velocity_x(0.0), m_velocity_y(0.0),
      m_max_speed(150.0), m_use_gravity(true),
      m_frenzy_timer(0.0), m_is_spawning_frenzy(false)
{}
Astrophage::~Astrophage() {}

void Astrophage::setup(int variant, const Vector2& spawn_pos, const Vector2& sun_pos) {
    m_variant     = variant;
    m_sun_position = sun_pos;
    set_global_position(spawn_pos);
    add_to_group("astrophage");

    // Random wiggle offset so enemies don't all move identically
    m_wiggle_offset = UtilityFunctions::randf() * 6.28318;

    struct Stats { float hp; float speed; float damage; int reward; };
    Stats table[] = {
        {30,60,0.05f,5}, {60,55,0.05f,10}, {120,35,0.0f,20},
        {50,60,0.05f,15},{40,55,0.05f,12}, {500,25,0.10f,100}
    };
    int idx = std::max(0, std::min(variant, 5));
    m_hp = m_max_hp = table[idx].hp;
    m_speed         = table[idx].speed;
    m_corona_damage = table[idx].damage;
    m_reward_credits = table[idx].reward;
    double mass_table[] = {1.0, 1.5, 3.0, 0.8, 1.2, 8.0};
    m_mass = mass_table[idx];
    m_velocity_x = 0.0;
    m_velocity_y = 0.0;
    m_max_speed = m_speed * (variant == PRIME ? 1.65 : 2.25);
    m_use_gravity = true;
    m_frenzy_timer = 0.0;
    m_is_spawning_frenzy = false;

    if (variant == MIMIC) m_is_cloaked = true;
}

void Astrophage::_process(double delta) {
    if (m_is_burrowing) return;

    Vector2 pos = get_global_position();
    Vector2 to_sun = (m_sun_position - pos);
    Vector2 dir = to_sun;
    float dist = dir.length();
    if (dist > 0) dir /= dist;

    if (m_use_gravity) {
        const double gravity_const = 5200000.0;
        double accel = gravity_const / std::max(static_cast<double>(dist) * static_cast<double>(dist) * m_mass, 1200.0);
        accel = std::min(accel, 360.0);
        m_velocity_x += dir.x * (accel + m_speed * 0.18) * delta;
        m_velocity_y += dir.y * (accel + m_speed * 0.18) * delta;

        double current_speed = std::sqrt(m_velocity_x * m_velocity_x + m_velocity_y * m_velocity_y);
        double capped_speed = m_max_speed * m_speed_modifier;
        if (current_speed > capped_speed && current_speed > 0.001) {
            m_velocity_x = (m_velocity_x / current_speed) * capped_speed;
            m_velocity_y = (m_velocity_y / current_speed) * capped_speed;
        }

        set_global_position(pos + Vector2(
            static_cast<float>(m_velocity_x * delta),
            static_cast<float>(m_velocity_y * delta)
        ));
    } else {
        set_global_position(pos + dir * static_cast<float>(m_speed * m_speed_modifier * delta));
    }

    // Check corona arrival (40px from sun center)
    if (dist < 40.0f) {
        emit_signal("reached_corona");
        queue_free();
    }
}

void Astrophage::take_hit(double damage, const String& source) {
    if (m_is_cloaked && source == String("photon_splitter")) return;

    if (m_variant == FARMER) {
        if (source == String("photon_splitter") || source == String("helios_cannon")) {
            m_hp    += damage * 0.5;
            m_max_hp = std::max(m_max_hp, m_hp);
            m_speed  = std::min(m_speed + 0.5, 150.0);
            m_max_speed = std::max(m_max_speed, m_speed * 2.25);
            return;
        }
    }

    if (m_variant == PRIME && m_prime_phase == 0) {
        if (source == String("bio_lab")) m_prime_phase = 1;
        return;
    }

    if (m_is_clustered) {
        _share_cluster_damage(damage);
        return;
    }

    m_hp -= damage;
    if (m_hp <= 0.0) _on_defeated();
}

void Astrophage::_on_defeated() {
    if (m_variant == BLOOM) {
        emit_signal("bloom_split", get_global_position());
    }
    if (m_variant == PRIME && m_prime_phase == 1) {
        m_prime_phase = 2;
        m_hp = 300;
        m_max_hp = 300;
        m_speed = std::min(m_speed * 1.8, 80.0);
        m_max_speed = m_speed * 1.85;
        m_frenzy_timer = 0.0;
        m_is_spawning_frenzy = true;
        return;
    }
    emit_signal("defeated", m_reward_credits);
    queue_free();
}

void Astrophage::_share_cluster_damage(double damage) {
    // Emit signal; GDScript handles finding nearby clustered nodes
    emit_signal("cluster_damage_request", damage);
    m_hp -= damage;
    if (m_hp <= 0.0) _on_defeated();
}

void Astrophage::apply_slow(double slow_factor) {
    m_speed_modifier = 1.0 - slow_factor;
}

void Astrophage::set_clustered(bool value) {
    m_is_clustered = value;
}
