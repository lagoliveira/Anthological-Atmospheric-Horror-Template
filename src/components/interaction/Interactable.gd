extends Node3D
class_name Interactable

# Base class for anything the player can interact with.
# Subclasses override _interact() to define behavior.
# The FPController or an InteractionManager casts a ray and calls interact().

@export var interaction_distance: float = 3.0
@export var interaction_prompt: String = "Interagir"
@export var highlight_on_look: bool = true
@export var highlight_color: Color = Color(1, 1, 1, 0.3)

var is_interactable: bool = true
var is_highlighted: bool = false

signal interacted(interactor: Node)
signal prompted(prompt: String)
signal prompt_removed()

func interact(interactor: Node) -> void:
	if not is_interactable:
		return
	_interact(interactor)
	interacted.emit(interactor)

func _interact(interactor: Node) -> void:
	# Override in subclasses
	pass

func set_highlight(enabled: bool) -> void:
	is_highlighted = enabled
	if enabled:
		prompted.emit(interaction_prompt)
	else:
		prompt_removed.emit()

func get_prompt() -> String:
	return interaction_prompt

func is_available() -> bool:
	return is_interactable
