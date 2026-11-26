extends CharacterBody3D
class_name FPController

# First-person player controller component.
# Handles movement, look (mouse), and footstep audio.
# Composed with Flashlight and SanityComponent for full player behavior.

@export var mouse_sensitivity: float = 0.002
@export var walk_speed: float = 4.5
@export var run_speed: float = 7.0
@export var jump_velocity: float = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var sprint_key: String = "Shift"

var velocity: Vector3 = Vector3.ZERO
var camera_pivot: Node3D
var camera: Camera3D
var yaw: float = 0.0
var pitch: float = 0.0

signal player_sprinted(is_sprinting: bool)
signal player_jumped()
signal player_landed()
signal footstep_played()

var was_on_floor: bool = false

func _ready() -> void:
	camera_pivot = get_node_or_null("%CameraPivot")
	camera = get_node_or_null("%Camera")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	was_on_floor = is_on_floor()

func _input(event: InputEvent) -> void:
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
	var is_on_floor: bool = is_on_floor()

	# Landing detection
	if was_on_floor == false and is_on_floor:
		player_landed.emit()
	was_on_floor = is_on_floor

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var target_speed: float = walk_speed
	var is_sprinting: bool = Input.is_action_pressed(sprint_key)
	if is_sprinting:
		target_speed = run_speed

	if is_on_floor:
		velocity = direction * target_speed
		# Footstep timer could go here
		if direction.length() > 0.1 and Input.is_action_just_pressed("move_forward"):
			footstep_played.emit()
	else:
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor:
		velocity.y = jump_velocity
		player_jumped.emit()

	move_and_slide()

	if is_sprinting and direction.length() > 0.1:
		player_sprinted.emit(true)
	else:
		player_sprinted.emit(false)

func get_camera() -> Camera3D:
	return camera

func get_camera_pivot() -> Node3D:
	return camera_pivot
