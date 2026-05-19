extends Control

@onready var btn_play = $menu_box/btn_play
@onready var btn_codex = $menu_box/btn_codex
@onready var btn_settings = $menu_box/btn_settings
@onready var btn_exit = $menu_box/btn_exit
@onready var title_label = $menu_box/title_label

func _ready():
	GameState.reset_state()
	
	btn_play.pressed.connect(_on_play)
	btn_codex.pressed.connect(_on_codex)
	btn_settings.pressed.connect(_on_settings)
	btn_exit.pressed.connect(_on_exit)
	
	# Animate title on startup
	title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5)

func _on_play():
	# Quick fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))

func _on_codex():
	var codex = preload("res://scenes/ui/codex.tscn").instantiate()
	add_child(codex)
	codex.show_standalone_mode()   # no pause needed in menu

func _on_settings():
	# MVP: show a "coming soon" popup, or skip entirely
	var popup = AcceptDialog.new()
	popup.title = "Settings"
	popup.dialog_text = "Audio & display settings — coming soon!\n(Not required for MVP)"
	add_child(popup)
	popup.popup_centered()

func _on_exit():
	get_tree().quit()

# Keyboard shortcut: Enter also starts game
func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_play()
