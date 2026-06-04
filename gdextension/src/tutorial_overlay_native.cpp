#include "tutorial_overlay_native.h"

#include <godot_cpp/classes/box_container.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/margin_container.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>

using namespace godot;

namespace {

constexpr double EDGE_MARGIN = 28.0;
constexpr double TARGET_GROW = 8.0;
const Vector2 PANEL_MIN_SIZE(470.0, 248.0);

Array tutorial_steps() {
    Array steps;
    Dictionary step;

    step["target"] = "sun";
    step["placement"] = "left_of_target";
    step["title"] = "DEFEND THE SUN";
    step["body"] = "This is the defense field. Astrophages push inward toward the sun; keep luminosity alive by building towers on the orbital rings.";
    steps.append(step);

    step = Dictionary();
    step["target"] = "tower_bay";
    step["placement"] = "above_target";
    step["title"] = "CHOOSE A TOWER";
    step["body"] = "The Tower Bay is your build tray. Pick a tower before or during a wave. Hover a tower any time to read its role, damage, range, and cautions.";
    steps.append(step);

    step = Dictionary();
    step["target"] = "slot";
    step["placement"] = "right_of_target";
    step["title"] = "BUILD ON ORBITAL SLOTS";
    step["body"] = "Click one of the small guide slots on a ring to place the selected tower. Click an existing tower later to upgrade it, sell it, or inspect its range.";
    steps.append(step);

    step = Dictionary();
    step["target"] = "start_wave";
    step["placement"] = "below_target";
    step["title"] = "START THE WAVE";
    step["body"] = "Start the next wave here when ready, or enable Auto Start beside it to launch ready waves after a short countdown. You can still spend earned Sol while enemies are moving.";
    steps.append(step);

    step = Dictionary();
    step["target"] = "wave_intel";
    step["placement"] = "left_of_target";
    step["title"] = "READ WAVE INTEL";
    step["body"] = "Wave Intel previews the next enemy group, reward, and ring notes. Use it to decide what to build before committing.";
    steps.append(step);

    step = Dictionary();
    step["target"] = "status";
    step["placement"] = "below_target";
    step["title"] = "WATCH STATUS AND CAMERA";
    step["body"] = "Sol, score, kills, flare, and luminosity live here. Press F when flare reads ready. Use WASD, edge hover, or right/middle drag to pan; mouse wheel zooms and Center Sun snaps back.";
    steps.append(step);

    return steps;
}

void add_margin(MarginContainer* margin, int left, int top, int right, int bottom) {
    margin->add_theme_constant_override("margin_left", left);
    margin->add_theme_constant_override("margin_top", top);
    margin->add_theme_constant_override("margin_right", right);
    margin->add_theme_constant_override("margin_bottom", bottom);
}

} // namespace

void TutorialOverlayNative::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_target_provider", "provider"), &TutorialOverlayNative::set_target_provider);
    ClassDB::bind_method(D_METHOD("_previous_step"), &TutorialOverlayNative::previous_step);
    ClassDB::bind_method(D_METHOD("_next_step"), &TutorialOverlayNative::next_step);
    ClassDB::bind_method(D_METHOD("_skip_tutorial"), &TutorialOverlayNative::skip_tutorial);
    ClassDB::bind_method(D_METHOD("_position_panel"), &TutorialOverlayNative::position_panel);
    ADD_SIGNAL(MethodInfo("tutorial_finished"));
    ADD_SIGNAL(MethodInfo("tutorial_skipped"));
}

void TutorialOverlayNative::_ready() {
    set_position(Vector2());
    if (get_viewport() != nullptr) {
        set_size(get_viewport_rect().size);
    }
    set_mouse_filter(Control::MOUSE_FILTER_STOP);
    set_focus_mode(Control::FOCUS_ALL);
    build_panel();
    apply_step();
    grab_focus();
    set_process(true);
}

void TutorialOverlayNative::_process(double) {
    if (get_viewport() != nullptr) {
        set_size(get_viewport_rect().size);
    }
    position_panel();
    queue_redraw();
}

void TutorialOverlayNative::_unhandled_input(const Ref<InputEvent>& event) {
    Ref<InputEventKey> key_event = event;
    if (key_event.is_null() || !key_event->is_pressed() || key_event->is_echo()) {
        return;
    }
    const Key keycode = key_event->get_keycode();
    if (keycode == KEY_ESCAPE) {
        skip_tutorial();
        if (get_viewport() != nullptr) {
            get_viewport()->set_input_as_handled();
        }
    } else if (keycode == KEY_ENTER || keycode == KEY_KP_ENTER) {
        next_step();
        if (get_viewport() != nullptr) {
            get_viewport()->set_input_as_handled();
        }
    }
}

void TutorialOverlayNative::_draw() {
    const Vector2 viewport_size = get_viewport_rect().size;
    draw_rect(Rect2(Vector2(), viewport_size), Color(0.0, 0.0, 0.0, 0.50), true);
    draw_grid(viewport_size);
    const Dictionary target_info = current_target_info();
    draw_target_highlight(target_info);
    draw_arrow_to_target(target_info);
}

void TutorialOverlayNative::set_target_provider(const Callable& provider) {
    target_provider = provider;
}

void TutorialOverlayNative::build_panel() {
    panel = memnew(PanelContainer);
    panel->set_name("TutorialPanel");
    panel->set_custom_minimum_size(PANEL_MIN_SIZE);
    panel->set_size(PANEL_MIN_SIZE);
    panel->set_mouse_filter(Control::MOUSE_FILTER_STOP);
    add_child(panel);

    MarginContainer* margin = memnew(MarginContainer);
    margin->set_name("TutorialMargin");
    add_margin(margin, 18, 16, 18, 16);
    panel->add_child(margin);

    VBoxContainer* box = memnew(VBoxContainer);
    box->set_name("TutorialBox");
    box->add_theme_constant_override("separation", 9);
    margin->add_child(box);

    step_label = memnew(Label);
    step_label->set_name("StepLabel");
    step_label->set_text("TRAINING");
    box->add_child(step_label);

    title_label = memnew(Label);
    title_label->set_name("TutorialTitle");
    title_label->set_text("TUTORIAL");
    title_label->set_clip_text(true);
    box->add_child(title_label);

    body_label = memnew(Label);
    body_label->set_name("TutorialBody");
    body_label->set_custom_minimum_size(Vector2(400.0, 74.0));
    body_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
    body_label->set_text("Tutorial text.");
    box->add_child(body_label);

    save_note_label = memnew(Label);
    save_note_label->set_name("SaveNote");
    save_note_label->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
    save_note_label->set_text("Skip or Finish saves this tutorial as complete. It will not replay automatically.");
    box->add_child(save_note_label);

    HBoxContainer* button_row = memnew(HBoxContainer);
    button_row->set_name("ButtonRow");
    button_row->set_alignment(BoxContainer::ALIGNMENT_END);
    button_row->add_theme_constant_override("separation", 8);
    box->add_child(button_row);

    skip_button = memnew(Button);
    skip_button->set_text("SKIP");
    skip_button->set_custom_minimum_size(Vector2(104.0, 38.0));
    skip_button->connect("pressed", Callable(this, "_skip_tutorial"));
    button_row->add_child(skip_button);

    back_button = memnew(Button);
    back_button->set_text("BACK");
    back_button->set_custom_minimum_size(Vector2(104.0, 38.0));
    back_button->connect("pressed", Callable(this, "_previous_step"));
    button_row->add_child(back_button);

    next_button = memnew(Button);
    next_button->set_text("NEXT");
    next_button->set_custom_minimum_size(Vector2(126.0, 38.0));
    next_button->connect("pressed", Callable(this, "_next_step"));
    button_row->add_child(next_button);

    apply_style();
}

void TutorialOverlayNative::apply_style() {
    Object* theme = space_theme();
    if (theme != nullptr) {
        theme->call("apply_fonts", this);
        theme->call("apply_deep_panel", panel, theme->get("COLOR_CYAN"));
        theme->call("apply_secondary_button", skip_button);
        theme->call("apply_secondary_button", back_button);
        theme->call("apply_primary_button", next_button);
    }

    step_label->add_theme_font_size_override("font_size", 10);
    step_label->add_theme_color_override("font_color", Color(0.34, 0.90, 1.0, 0.88));
    title_label->add_theme_font_size_override("font_size", 20);
    title_label->add_theme_color_override("font_color", theme != nullptr ? Color(theme->get("COLOR_GOLD")) : Color(1.0, 0.88, 0.36));
    body_label->add_theme_font_size_override("font_size", 15);
    body_label->add_theme_color_override("font_color", theme != nullptr ? Color(theme->get("COLOR_TEXT")) : Color(0.90, 0.94, 1.0));
    save_note_label->add_theme_font_size_override("font_size", 11);
    save_note_label->add_theme_color_override("font_color", Color(0.70, 0.84, 0.94, 0.82));

    Button* buttons[] = {skip_button, back_button, next_button};
    for (Button* button : buttons) {
        button->add_theme_font_size_override("font_size", 14);
        button->set_default_cursor_shape(Control::CURSOR_POINTING_HAND);
    }
}

void TutorialOverlayNative::apply_step() {
    const Array steps = tutorial_steps();
    const Dictionary step = current_step();
    step_label->set_text(vformat("MISSION TRAINING %d/%d", step_index + 1, steps.size()));
    title_label->set_text(String(step.get("title", "TUTORIAL")));
    body_label->set_text(String(step.get("body", "")));
    back_button->set_disabled(step_index == 0);
    next_button->set_text(step_index >= steps.size() - 1 ? "FINISH" : "NEXT");
    call_deferred("_position_panel");
    queue_redraw();
}

void TutorialOverlayNative::previous_step() {
    if (step_index <= 0) {
        return;
    }
    --step_index;
    apply_step();
}

void TutorialOverlayNative::next_step() {
    const Array steps = tutorial_steps();
    if (step_index >= steps.size() - 1) {
        emit_signal("tutorial_finished");
        queue_free();
        return;
    }
    ++step_index;
    apply_step();
}

void TutorialOverlayNative::skip_tutorial() {
    emit_signal("tutorial_skipped");
    queue_free();
}

Dictionary TutorialOverlayNative::current_step() const {
    const Array steps = tutorial_steps();
    return steps[Math::clamp(step_index, 0, static_cast<int>(steps.size()) - 1)];
}

Dictionary TutorialOverlayNative::target_map() const {
    if (target_provider.is_valid()) {
        Variant targets = target_provider.call();
        if (targets.get_type() == Variant::DICTIONARY) {
            return targets;
        }
    }
    return Dictionary();
}

Dictionary TutorialOverlayNative::current_target_info() const {
    const Dictionary step = current_step();
    const String target_key = String(step.get("target", ""));
    const Dictionary targets = target_map();
    const Variant target_value = targets.get(target_key, Dictionary());
    if (target_value.get_type() == Variant::DICTIONARY) {
        const Dictionary target_info = target_value;
        if (!target_info.is_empty()) {
            return target_info;
        }
    }
    Dictionary fallback;
    fallback["type"] = "rect";
    fallback["rect"] = Rect2(get_viewport_rect().size * 0.5 - Vector2(80.0, 80.0), Vector2(160.0, 160.0));
    return fallback;
}

void TutorialOverlayNative::position_panel() {
    if (panel == nullptr) {
        return;
    }
    const Vector2 viewport_size = get_viewport_rect().size;
    Vector2 panel_size = panel->get_combined_minimum_size();
    panel_size.x = MAX(panel_size.x, PANEL_MIN_SIZE.x);
    panel_size.y = MAX(panel_size.y, PANEL_MIN_SIZE.y);
    panel->set_size(panel_size);

    const Dictionary step = current_step();
    const Rect2 rect = target_rect(current_target_info());
    const String placement = String(step.get("placement", "bottom_left"));
    Vector2 pos(EDGE_MARGIN, EDGE_MARGIN);

    if (placement == "above_target") {
        pos = Vector2(rect.position.x, rect.position.y - panel_size.y - 18.0);
    } else if (placement == "below_target") {
        pos = Vector2(rect.position.x, rect.position.y + rect.size.y + 18.0);
    } else if (placement == "left_of_target") {
        pos = Vector2(rect.position.x - panel_size.x - 22.0, rect.get_center().y - panel_size.y * 0.5);
    } else if (placement == "right_of_target") {
        pos = Vector2(rect.position.x + rect.size.x + 22.0, rect.get_center().y - panel_size.y * 0.5);
    } else if (placement == "top_right") {
        pos = Vector2(viewport_size.x - panel_size.x - EDGE_MARGIN, EDGE_MARGIN);
    } else if (placement == "bottom_right") {
        pos = Vector2(viewport_size.x - panel_size.x - EDGE_MARGIN, viewport_size.y - panel_size.y - EDGE_MARGIN);
    } else if (placement == "bottom_left") {
        pos = Vector2(EDGE_MARGIN, viewport_size.y - panel_size.y - EDGE_MARGIN);
    }

    panel->set_position(Vector2(
        Math::clamp<double>(pos.x, EDGE_MARGIN, MAX(EDGE_MARGIN, double(viewport_size.x - panel_size.x - EDGE_MARGIN))),
        Math::clamp<double>(pos.y, EDGE_MARGIN, MAX(EDGE_MARGIN, double(viewport_size.y - panel_size.y - EDGE_MARGIN)))));
}

void TutorialOverlayNative::draw_grid(const Vector2& viewport_size) {
    const Color grid_color(0.16, 0.80, 0.96, 0.055);
    for (int x = 0; x <= static_cast<int>(viewport_size.x); x += 72) {
        draw_line(Vector2(static_cast<double>(x), 0.0), Vector2(static_cast<double>(x), viewport_size.y), grid_color, 1.0);
    }
    for (int y = 0; y <= static_cast<int>(viewport_size.y); y += 72) {
        draw_line(Vector2(0.0, static_cast<double>(y)), Vector2(viewport_size.x, static_cast<double>(y)), grid_color, 1.0);
    }
}

void TutorialOverlayNative::draw_target_highlight(const Dictionary& target_info) {
    Object* theme = space_theme();
    const Color accent = theme != nullptr ? Color(theme->get("COLOR_GOLD")) : Color(1.0, 0.82, 0.28);
    const Color cyan = theme != nullptr ? Color(theme->get("COLOR_CYAN")) : Color(0.34, 0.90, 1.0);
    if (String(target_info.get("type", "rect")) == "circle") {
        const Vector2 center = target_info.get("center", get_viewport_rect().size * 0.5);
        const double radius = double(target_info.get("radius", 42.0)) + TARGET_GROW;
        draw_circle(center, radius + 10.0, Color(0.22, 0.84, 0.94, 0.08));
        draw_arc(center, radius, 0.0, Math_TAU, 96, accent, 2.4, true);
        draw_arc(center, radius + 8.0, -0.7, 0.7, 32, cyan, 2.0, true);
        draw_arc(center, radius + 8.0, Math_PI - 0.7, Math_PI + 0.7, 32, cyan, 2.0, true);
        return;
    }

    const Rect2 rect = target_rect(target_info).grow(TARGET_GROW);
    draw_rect(rect, Color(0.22, 0.84, 0.94, 0.08), true);
    draw_rect(rect, accent, false, 2.0);
    const double corner = MIN(34.0, MIN(rect.size.x, rect.size.y) * 0.28);
    draw_corner(rect.position, Vector2(1.0, 0.0), Vector2(0.0, 1.0), corner);
    draw_corner(rect.position + Vector2(rect.size.x, 0.0), Vector2(-1.0, 0.0), Vector2(0.0, 1.0), corner);
    draw_corner(rect.position + Vector2(0.0, rect.size.y), Vector2(1.0, 0.0), Vector2(0.0, -1.0), corner);
    draw_corner(rect.position + rect.size, Vector2(-1.0, 0.0), Vector2(0.0, -1.0), corner);
}

void TutorialOverlayNative::draw_corner(const Vector2& origin, const Vector2& horizontal, const Vector2& vertical, double length) {
    Object* theme = space_theme();
    const Color cyan = theme != nullptr ? Color(theme->get("COLOR_CYAN")) : Color(0.34, 0.90, 1.0);
    draw_line(origin, origin + horizontal * length, cyan, 2.0);
    draw_line(origin, origin + vertical * length, cyan, 2.0);
}

void TutorialOverlayNative::draw_arrow_to_target(const Dictionary& target_info) {
    if (panel == nullptr) {
        return;
    }
    const Rect2 panel_rect = Rect2(panel->get_position(), panel->get_size()).grow(4.0);
    Vector2 target_center = target_rect(target_info).get_center();
    if (String(target_info.get("type", "rect")) == "circle") {
        target_center = target_info.get("center", target_center);
    }
    const Vector2 start = nearest_panel_edge(panel_rect, target_center);
    Vector2 direction = target_center - start;
    if (direction.length() < 8.0) {
        return;
    }
    direction = direction.normalized();
    const Vector2 end = target_center - direction * 16.0;
    const Vector2 normal(-direction.y, direction.x);
    const Color gold(1.0, 0.82, 0.28, 0.92);
    draw_line(start, end, gold, 2.0);
    draw_line(end, end - direction * 15.0 + normal * 8.0, gold, 2.0);
    draw_line(end, end - direction * 15.0 - normal * 8.0, gold, 2.0);
    Object* theme = space_theme();
    draw_circle(start, 3.0, theme != nullptr ? Color(theme->get("COLOR_CYAN")) : Color(0.34, 0.90, 1.0));
}

Vector2 TutorialOverlayNative::nearest_panel_edge(const Rect2& panel_rect, const Vector2& target_center) const {
    const Vector2 panel_center = panel_rect.get_center();
    const Vector2 delta = target_center - panel_center;
    if (Math::abs(delta.x / MAX(panel_rect.size.x, 1.0)) > Math::abs(delta.y / MAX(panel_rect.size.y, 1.0))) {
        const double x = delta.x > 0.0 ? panel_rect.position.x + panel_rect.size.x : panel_rect.position.x;
        return Vector2(x, Math::clamp(target_center.y, panel_rect.position.y, panel_rect.position.y + panel_rect.size.y));
    }
    const double y = delta.y > 0.0 ? panel_rect.position.y + panel_rect.size.y : panel_rect.position.y;
    return Vector2(Math::clamp(target_center.x, panel_rect.position.x, panel_rect.position.x + panel_rect.size.x), y);
}

Rect2 TutorialOverlayNative::target_rect(const Dictionary& target_info) const {
    if (String(target_info.get("type", "rect")) == "circle") {
        const Vector2 center = target_info.get("center", get_viewport_rect().size * 0.5);
        const double radius = double(target_info.get("radius", 42.0));
        return Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0));
    }
    return target_info.get("rect", Rect2(get_viewport_rect().size * 0.5 - Vector2(80.0, 80.0), Vector2(160.0, 160.0)));
}

Object* TutorialOverlayNative::space_theme() const {
    static Ref<RefCounted> resource;
    if (resource.is_null()) {
        resource = Ref<RefCounted>(Object::cast_to<RefCounted>(ClassDB::instantiate("SpaceThemeNative")));
    }
    return resource.ptr();
}
