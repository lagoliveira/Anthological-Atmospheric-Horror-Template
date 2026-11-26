extends Node
class_name InteractionManager

# Player interaction component.
# Casts a ray from the camera each physics frame to find the focused
# Interactable and triggers it when the interact action is pressed.
#
# Attach as a child of the player. Interactables are Area3D nodes, so the
# ray query is configured to detect areas as well as bodies.

@export var interact_action: String = "interact"
@export var ray_length: float = 3.0
@export var collision_mask: int = 1

var current_target: Interactable = null

signal target_changed(target: Interactable)
signal interaction_performed(target: Interactable)

@onready var camera: Camera3D = null

func _ready() -> void:
	var player: Node3D = get_parent() as Node3D
	if player:
		camera = player.get_node_or_null("%Camera") as Camera3D
		var game_manager: GameManager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.set_player(player)

func _physics_process(_delta: float) -> void:
	_update_target()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(interact_action):
		return
	if current_target and current_target.is_available():
		current_target.interact(get_parent())
		interaction_performed.emit(current_target)

func _update_target() -> void:
	var found: Interactable = null

	if camera:
		var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var origin: Vector3 = camera.global_position
		var target: Vector3 = origin + (-camera.global_transform.basis.z) * ray_length
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target, collision_mask)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			found = hit.get("collider", null) as Interactable

	if found == current_target:
		return

	if current_target:
		current_target.set_highlight(false)
	current_target = found
	if current_target:
		current_target.set_highlight(true)
	target_changed.emit(current_target)
