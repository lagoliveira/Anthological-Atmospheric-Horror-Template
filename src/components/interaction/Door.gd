extends Interactable
class_name Door

# Door interactable: opens/closes with animation or tween.
# Can be locked, requiring a key item.

@export var door_node: Node3D
@export var open_angle: float = deg_to_rad(90)
@export var open_speed: float = 4.0
@export var is_locked: bool = false
@export var required_key_id: String = ""
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var locked_sound: AudioStream

var is_open: bool = false
var is_animating: bool = false
var closed_rotation: Quaternion
var open_rotation: Quaternion

func _ready() -> void:
	interaction_prompt = "Abrir porta"
	if door_node:
		closed_rotation = door_node.rotation_quaternion
		open_rotation = closed_rotation * Quaternion(Vector3.UP, open_angle)

func _interact(interactor: Node) -> void:
	if is_locked:
		var game_manager: GameManager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.inventory_manager.has_item(required_key_id):
			is_locked = false
			_interact(interactor)
		else:
			if locked_sound:
				var audio_manager: AudioManager = get_node_or_null("/root/AudioManager")
				if audio_manager:
					audio_manager.play_sound(locked_sound)
			return

	if is_animating:
		return

	is_animating = true
	is_open = !is_open

	var target: Quaternion
	if is_open:
		target = open_rotation
	else:
		target = closed_rotation
	var tween: Tween = create_tween()
	tween.tween_property(door_node, "rotation_quaternion", target, 1.0 / open_speed)
	tween.tween_callback(func(): is_animating = false)

	if is_open and open_sound:
		var audio_manager: AudioManager = get_node_or_null("/root/AudioManager")
		if audio_manager:
			audio_manager.play_sound(open_sound)
	elif not is_open and close_sound:
		var audio_manager: AudioManager = get_node_or_null("/root/AudioManager")
		if audio_manager:
			audio_manager.play_sound(close_sound)

	interacted.emit(interactor)

func lock() -> void:
	is_locked = true

func unlock() -> void:
	is_locked = false
