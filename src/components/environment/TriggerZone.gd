extends Area3D
class_name TriggerZone

# Area trigger for gameplay events.
# Emits signals when a body enters/exits the zone.
# Used for scripted events, ambient changes, and gameplay triggers.

@export var trigger_on_enter: bool = true
@export var trigger_on_exit: bool = false
@export var required_tag: String = "Player"  # group name to filter
@export var repeatable: bool = false
@export var cooldown_seconds: float = 0.0

var has_triggered: bool = false
var cooldown_timer: float = 0.0

signal zone_entered(body: Node)
signal zone_exited(body: Node)
signal zone_activated(body: Node)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta

func _on_body_entered(body: Node) -> void:
	if required_tag != "" and not body.is_in_group(required_tag):
		return
	zone_entered.emit(body)
	if trigger_on_enter:
		_try_activate(body)

func _on_body_exited(body: Node) -> void:
	if required_tag != "" and not body.is_in_group(required_tag):
		return
	zone_exited.emit(body)
	if trigger_on_exit:
		_try_activate(body)

func _try_activate(body: Node) -> void:
	if cooldown_timer > 0:
		return
	if not repeatable and has_triggered:
		return
	has_triggered = true
	if cooldown_seconds > 0:
		cooldown_timer = cooldown_seconds
	zone_activated.emit(body)

func reset() -> void:
	has_triggered = false
	cooldown_timer = 0.0
