extends CanvasLayer
class_name MainMenu

# Main menu for the anthology template.
# Wires the buttons and uses the FadeManager for scene transitions.

@export var game_scene_path: String = "res://scenes/TestScene.tscn"

@onready var start_button: Button = get_node_or_null("MenuContainer/StartButton") as Button
@onready var quit_button: Button = get_node_or_null("MenuContainer/QuitButton") as Button

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	GameManager.get_fade_manager().change_scene_fade(game_scene_path, 1.0)

func _on_quit_pressed() -> void:
	get_tree().quit()
