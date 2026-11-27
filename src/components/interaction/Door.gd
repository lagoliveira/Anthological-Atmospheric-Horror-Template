extends Interactable
class_name Door

# Door interactable: opens/closes with a tween.
# Can be locked, requiring a key item in the player's inventory.

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
	if door_node == null:
		door_node = get_parent() as Node3D
	if door_node:
		closed_rotation = door_node.quaternion
		open_rotation = closed_rotation * Quaternion(Vector3.UP, open_angle)
	_update_prompt()

func _update_prompt() -> void:
	if is_locked:
		interaction_prompt = "Trancada"
	elif is_open:
		interaction_prompt = "Fechar porta"
	else:
		interaction_prompt = "Abrir porta"

func _interact(interactor: Node) -> void:
	if is_animating:
		return

	if is_locked:
		if not _try_unlock():
			return

	is_animating = true
	is_open = not is_open
	_update_prompt()

	var target: Quaternion
	if is_open:
		target = open_rotation
	else:
		target = closed_rotation

	var tween: Tween = create_tween()
	tween.tween_property(door_node, "quaternion", target, 1.0 / open_speed)
	tween.tween_callback(func(): is_animating = false)

	_play_sound(open_sound if is_open else close_sound)

func _try_unlock() -> bool:
	if not GameManager.get_inventory_manager().has_item(required_key_id):
		_play_sound(locked_sound)
		return false
	is_locked = false
	_update_prompt()
	return true

func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	GameManager.get_audio_manager().play_sound(stream)

func lock() -> void:
	is_locked = true
	_update_prompt()

func unlock() -> void:
	is_locked = false
	_update_prompt()
