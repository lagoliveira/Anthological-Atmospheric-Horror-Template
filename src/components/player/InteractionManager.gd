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
@export var camera: Camera3D = null

var current_target: Interactable = null

signal target_changed(target: Interactable)
signal interaction_performed(target: Interactable)

var player: Node3D = null

func _ready() -> void:
	player = get_parent() as Node3D
	if player:
		if camera == null:
			camera = _find_camera()
		GameManager.set_player(player)

func _find_camera() -> Camera3D:
	# Resolve the camera by type so the component does not depend on a
	# hard-coded node path or on the scene's owner chain.
	var entity: Node = get_parent()
	if entity == null:
		return null
	var found: Array[Node] = entity.find_children("*", "Camera3D", true, false)
	if found.is_empty():
		return null
	return found[0] as Camera3D

func _physics_process(_delta: float) -> void:
	_update_target()

func _unhandled_input(event: InputEvent) -> void:
	# `is_action_pressed` also matches keyboard echo events, which would make
	# a single key press trigger the interaction several times.
	if not event.is_action_pressed(interact_action) or event.is_echo():
		return
	if not is_instance_valid(current_target) or not current_target.is_available():
		return
	var interactor: Node = player if player else get_parent()
	current_target.interact(interactor)
	interaction_performed.emit(current_target)

func _update_target() -> void:
	var found: Interactable = null

	# The previous target may have been freed (collectible notes free
	# themselves), so the reference must be validated before use.
	if current_target != null and not is_instance_valid(current_target):
		current_target = null

	if camera:
		# This component is a plain Node, so the 3D world must come from the
		# camera (a Node3D) rather than from `self`.
		var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
		var origin: Vector3 = camera.global_position
		var target: Vector3 = origin + (-camera.global_transform.basis.z) * ray_length
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target, collision_mask)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		# Never let the ray hit the player's own collision shape.
		var exclude: Array[RID] = []
		if player is CollisionObject3D:
			exclude.append((player as CollisionObject3D).get_rid())
		query.exclude = exclude
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			var collider: Interactable = hit.get("collider", null) as Interactable
			if collider:
				# Each interactable can define its own maximum reach. The hit
				# is discarded when it is farther away than that limit.
				var hit_position: Vector3 = hit.get("position", origin)
				var hit_distance: float = origin.distance_to(hit_position)
				if collider.interaction_distance <= 0.0 or hit_distance <= collider.interaction_distance:
					found = collider

	if found == current_target:
		return

	if current_target and is_instance_valid(current_target):
		current_target.set_highlight(false)
	current_target = found
	if current_target:
		current_target.set_highlight(true)
	target_changed.emit(current_target)
