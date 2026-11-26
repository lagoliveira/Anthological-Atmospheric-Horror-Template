extends Node
class_name Component

# Base class for all components in the modular architecture.
# Components are Node children that encapsulate a single responsibility
# and communicate through signals. They can be added to any Node3D/Node
# to compose complex entities without deep inheritance hierarchies.

signal component_ready()
signal component_exited_tree()

# Reference to the entity (owner node) this component is attached to.
@export var entity: Node = null setget _set_entity, _get_entity

func _set_entity(value: Node):
	entity = value

func _get_entity() -> Node:
	return entity if entity else get_owner_or_null()

func _ready() -> void:
	component_ready.emit()

func _exit_tree() -> void:
	component_exited_tree.emit()

# Override in subclasses to define per-frame logic.
func _component_process(delta: float) -> void:
	pass

# Override in subclasses to define physics-frame logic.
func _component_physics_process(delta: float) -> void:
	pass
