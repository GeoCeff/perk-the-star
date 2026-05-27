#pragma once

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class SunNode : public Node2D {
    GDCLASS(SunNode, Node2D)

private:
    double m_luminosity;
    int    m_burrower_count;
    double m_drain_accumulator;

protected:
    static void _bind_methods();

public:
    SunNode();
    ~SunNode();

    void _process(double delta) override;

    void take_damage(double amount);
    void add_burrower();
    void remove_burrower();

    double get_luminosity() const { return m_luminosity; }
    void   set_luminosity(double value);
    int    get_burrower_count() const { return m_burrower_count; }
    String get_expression_state() const;
    int    get_luminosity_percent() const;
};

}
