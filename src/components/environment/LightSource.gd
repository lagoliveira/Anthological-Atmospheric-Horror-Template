extends Node3D
class_name LightSource

# Environmental light source component.
# Can be toggled (breakable bulbs, flickering lamps) and affects sanity darkness.

@export var light_node: Light3D
@export var is_on_by_default: bool = true
@export var can_be_toggled: bool = false
@export var flicker: bool = false
@export var flicker_intensity: float = 0.2
@export var affects_sanity: bool = true

var is_on: bool = true
var flicker_timer: float = 0.0
var original_energy: float = 1.0

func _ready() -> void:
	is_on = is_on_by_default
	if light_node:
		original_energy = light_node.energy
		light_node.enabled = is_on

func _process(delta: float) -> void:
	if flicker and is_on and light_node:
		flicker_timer += delta
		if flicker_timer >= 0.05:
			light_node.energy = original_energy * (1.0 + (randf() - 0.5) * flicker_intensity)
			flicker_timer = 0.0

func toggle() -> void:
	if not can_be_toggled:
		return
	is_on = !is_on
	if light_node:
		light_node.enabled = is_on

func turn_on() -> void:
	is_on = true
	if light_node:
		light_node.enabled = true

func turn_off() -> void:
	is_on = false
	if light_node:
		light_node.enabled = false

func is_lit() -> bool:
	return is_on
