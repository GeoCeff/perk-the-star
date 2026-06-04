#include "sun_node.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/core/property_info.hpp>

using namespace godot;

void SunNode::_bind_methods() {
    ClassDB::bind_method(D_METHOD("take_damage","amount"),  &SunNode::take_damage);
    ClassDB::bind_method(D_METHOD("add_burrower"),          &SunNode::add_burrower);
    ClassDB::bind_method(D_METHOD("remove_burrower"),       &SunNode::remove_burrower);
    ClassDB::bind_method(D_METHOD("get_luminosity"),        &SunNode::get_luminosity);
    ClassDB::bind_method(D_METHOD("set_luminosity","v"),    &SunNode::set_luminosity);
    ClassDB::bind_method(D_METHOD("get_burrower_count"),    &SunNode::get_burrower_count);
    ClassDB::bind_method(D_METHOD("get_expression_state"),  &SunNode::get_expression_state);
    ClassDB::bind_method(D_METHOD("get_luminosity_percent"),&SunNode::get_luminosity_percent);

    ADD_SIGNAL(MethodInfo("luminosity_changed",
        PropertyInfo(Variant::FLOAT,"value")));
    ADD_SIGNAL(MethodInfo("sun_extinguished"));
    ADD_SIGNAL(MethodInfo("expression_changed",
        PropertyInfo(Variant::STRING,"expression")));

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT,"luminosity"),
        "set_luminosity","get_luminosity");
}

SunNode::SunNode()
    : m_luminosity(1.0), m_burrower_count(0), m_drain_accumulator(0.0)
{}
SunNode::~SunNode() {}

void SunNode::_process(double delta) {
    if (m_burrower_count <= 0) return;
    m_drain_accumulator += 0.02 * m_burrower_count * delta;
    if (m_drain_accumulator >= 0.001) {
        take_damage(m_drain_accumulator);
        m_drain_accumulator = 0.0;
    }
}

void SunNode::take_damage(double amount) {
    if (amount <= 0.0) return;
    String old_expr = get_expression_state();
    m_luminosity -= amount;
    if (m_luminosity < 0.0) m_luminosity = 0.0;
    emit_signal("luminosity_changed", m_luminosity);
    String new_expr = get_expression_state();
    if (new_expr != old_expr) emit_signal("expression_changed", new_expr);
    if (m_luminosity <= 0.0) emit_signal("sun_extinguished");
}

void SunNode::set_luminosity(double v) {
    m_luminosity = v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
}

void SunNode::add_burrower()    { m_burrower_count++; }
void SunNode::remove_burrower() { if (m_burrower_count > 0) m_burrower_count--; }

String SunNode::get_expression_state() const {
    if (m_luminosity > 0.8)  return "happy";
    if (m_luminosity > 0.6)  return "concerned";
    if (m_luminosity > 0.3)  return "distressed";
    return "critical";
}

int SunNode::get_luminosity_percent() const {
    return static_cast<int>(m_luminosity * 100.0);
}
