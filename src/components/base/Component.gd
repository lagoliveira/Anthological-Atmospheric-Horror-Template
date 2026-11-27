extends Node
class_name Component

# Base class for logic-only components (those that do not need a specific
# native node type such as Node3D or CharacterBody3D).
#
# Components are Node children that encapsulate a single responsibility and
# communicate through signals. They can be added to any entity to compose
# complex behaviour without deep inheritance hierarchies.
#
# NOTE: Godot has single inheritance, so components that must be a specific
# 3D type (FPController, Flashlight, LightSource, AudioEmitter, TriggerZone)
# extend their native type directly and cannot also extend this class.

signal component_ready()
signal component_exited_tree()

# Reference to the entity this component is attached to.
# Falls back to the parent node when not explicitly assigned.
@export var entity: Node = null

func get_entity() -> Node:
	if entity:
		return entity
	return get_parent()

func _ready() -> void:
	if entity == null:
		entity = get_parent()
	component_ready.emit()

func _exit_tree() -> void:
	component_exited_tree.emit()

func _process(delta: float) -> void:
	_component_process(delta)

func _physics_process(delta: float) -> void:
	_component_physics_process(delta)

# Override in subclasses to define per-frame logic.
func _component_process(delta: float) -> void:
	pass

# Override in subclasses to define physics-frame logic.
func _component_physics_process(delta: float) -> void:
	pass
