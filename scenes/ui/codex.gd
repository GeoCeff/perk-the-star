extends Control

@onready var title_label = $PanelContainer/VBoxContainer/title_label
@onready var close_button = $PanelContainer/VBoxContainer/close_button

func _ready():
	title_label.text = "GAME PARAPHERNALIAS — PERK THE STAR"
	close_button.text = "CLOSE"
	close_button.pressed.connect(queue_free)

func show_standalone_mode():
	visible = true
