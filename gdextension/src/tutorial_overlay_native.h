#pragma once

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class Button;
class Label;
class PanelContainer;

class TutorialOverlayNative : public Control {
    GDCLASS(TutorialOverlayNative, Control)

protected:
    static void _bind_methods();

public:
    void _ready() override;
    void _process(double delta) override;
    void _unhandled_input(const Ref<InputEvent>& event) override;
    void _draw() override;

    void set_target_provider(const Callable& provider);

private:
    Callable target_provider;
    int step_index = 0;

    PanelContainer* panel = nullptr;
    Label* step_label = nullptr;
    Label* title_label = nullptr;
    Label* body_label = nullptr;
    Label* save_note_label = nullptr;
    Button* back_button = nullptr;
    Button* next_button = nullptr;
    Button* skip_button = nullptr;

    void build_panel();
    void apply_style();
    void apply_step();
    void previous_step();
    void next_step();
    void skip_tutorial();
    Dictionary current_step() const;
    Dictionary target_map() const;
    Dictionary current_target_info() const;
    void position_panel();
    void draw_grid(const Vector2& viewport_size);
    void draw_target_highlight(const Dictionary& target_info);
    void draw_corner(const Vector2& origin, const Vector2& horizontal, const Vector2& vertical, double length);
    void draw_arrow_to_target(const Dictionary& target_info);
    Vector2 nearest_panel_edge(const Rect2& panel_rect, const Vector2& target_center) const;
    Rect2 target_rect(const Dictionary& target_info) const;
    Object* space_theme() const;
};

}
