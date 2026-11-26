extends Node3D
class_name Flashlight

# Flashlight component for the player.
# Toggles a SpotLight3D with battery consumption and recharge.
# Essential for atmospheric horror: limited light creates tension.

@export var light_node: SpotLight3D
@export var battery_capacity: float = 100.0
@export var battery_drain_rate: float = 15.0  # per second when on
@export var battery_recharge_rate: float = 8.0  # per second when off
@export var low_battery_threshold: float = 20.0
@export var flicker_at_low_battery: bool = true
@export var toggle_action: String = "flashlight"

var battery: float = 100.0
var is_on: bool = false
var is_flickering: bool = false
var flicker_timer: float = 0.0

signal flashlight_toggled(is_on: bool)
signal battery_changed(current: float, max: float)
signal low_battery_reached()
signal battery_depleted()

func _ready() -> void:
	battery = battery_capacity
	if light_node:
		light_node.visible = is_on

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(toggle_action):
		toggle()

	if is_on:
		battery -= battery_drain_rate * delta
		if battery <= 0:
			battery = 0
			is_on = false
			if light_node:
				light_node.visible = false
			battery_depleted.emit()
		elif flicker_at_low_battery and battery <= low_battery_threshold:
			_start_flicker()
	else:
		battery += battery_recharge_rate * delta
		if battery >= battery_capacity:
			battery = battery_capacity

	battery = clamp(battery, 0, battery_capacity)
	battery_changed.emit(battery, battery_capacity)

	if is_flickering:
		_update_flicker(delta)

func toggle() -> void:
	if battery <= 0:
		return
	is_on = !is_on
	if light_node:
		light_node.visible = is_on
	flashlight_toggled.emit(is_on)

func _start_flicker() -> void:
	is_flickering = true
	flicker_timer = 0.0

func _update_flicker(delta: float) -> void:
	if not light_node:
		return
	flicker_timer += delta
	if flicker_timer >= 0.05:
		light_node.visible = not light_node.visible if randf() < 0.3 else light_node.visible
		flicker_timer = 0.0
	if battery > low_battery_threshold:
		is_flickering = false
		light_node.visible = is_on

func get_battery_percentage() -> float:
	return battery / battery_capacity * 100.0

func recharge(amount: float) -> void:
	battery = clamp(battery + amount, 0, battery_capacity)
	battery_changed.emit(battery, battery_capacity)
