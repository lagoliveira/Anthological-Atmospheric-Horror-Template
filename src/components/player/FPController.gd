extends CharacterBody3D
class_name FPController

# First-person player controller component.
# Handles movement, look (mouse), jumping, sprinting and footstep events.
# Composed with Flashlight, SanityComponent and InteractionManager for
# the full player behaviour.

@export var mouse_sensitivity: float = 0.002
@export var walk_speed: float = 4.5
@export var run_speed: float = 7.0
@export var jump_velocity: float = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var sprint_action: String = "sprint"
@export var footstep_distance: float = 2.2

var move_velocity: Vector3 = Vector3.ZERO
var camera_pivot: Node3D
var camera: Camera3D
var yaw: float = 0.0
var pitch: float = 0.0

signal player_sprinted(is_sprinting: bool)
signal player_jumped()
signal player_landed()
signal footstep_played()

var was_on_floor: bool = false
var footstep_accumulator: float = 0.0
var _was_sprinting: bool = false

func _ready() -> void:
	camera_pivot = get_node_or_null("CameraPivot") as Node3D
	camera = _find_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	was_on_floor = is_on_floor()

func _find_camera() -> Camera3D:
	# Resolve the camera by type instead of by hard-coded path so the
	# component keeps working if the scene layout changes.
	if camera_pivot:
		var under_pivot: Array[Node] = camera_pivot.find_children("*", "Camera3D", true, false)
		if not under_pivot.is_empty():
			return under_pivot[0] as Camera3D
	var anywhere: Array[Node] = find_children("*", "Camera3D", true, false)
	if not anywhere.is_empty():
		return anywhere[0] as Camera3D
	return null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -deg_to_rad(90), deg_to_rad(90))

		if camera_pivot:
			camera_pivot.rotation.y = yaw
			camera_pivot.rotation.x = pitch
		elif camera:
			camera.rotation.y = yaw
			camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()

	if not was_on_floor and on_floor:
		player_landed.emit()
	was_on_floor = on_floor

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = _get_move_direction(input_dir)

	var is_sprinting: bool = Input.is_action_pressed(sprint_action) and input_dir.length() > 0.1
	var target_speed: float = run_speed if is_sprinting else walk_speed

	if on_floor:
		# Clear any residual vertical velocity so the body does not keep
		# sinking into the floor after landing.
		move_velocity.y = 0.0
		move_velocity.x = direction.x * target_speed
		move_velocity.z = direction.z * target_speed
	else:
		move_velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and on_floor:
		move_velocity.y = jump_velocity
		player_jumped.emit()

	velocity = move_velocity
	move_and_slide()

	_update_footsteps(delta, direction.length() > 0.1, is_sprinting)

	# Only emit on transitions to avoid flooding listeners every frame.
	if is_sprinting != _was_sprinting:
		_was_sprinting = is_sprinting
		player_sprinted.emit(is_sprinting)

func _get_move_direction(input_dir: Vector2) -> Vector3:
	var basis: Basis = Basis.IDENTITY
	if camera_pivot:
		basis = camera_pivot.global_transform.basis
	elif camera:
		basis = camera.global_transform.basis

	var direction: Vector3 = basis * Vector3(input_dir.x, 0, input_dir.y)

	# The camera basis includes the look pitch. Movement must stay on the
	# horizontal plane, otherwise looking up/down makes the player float or
	# sink while walking.
	direction.y = 0.0
	if direction.length_squared() < 0.000001:
		return Vector3.ZERO
	return direction.normalized()

func _update_footsteps(delta: float, is_moving: bool, is_sprinting: bool) -> void:
	if not is_moving or not is_on_floor():
		return
	footstep_accumulator += delta * (run_speed if is_sprinting else walk_speed)
	if footstep_accumulator >= footstep_distance:
		footstep_accumulator = 0.0
		footstep_played.emit()

func get_camera() -> Camera3D:
	return camera

func get_camera_pivot() -> Node3D:
	return camera_pivot
