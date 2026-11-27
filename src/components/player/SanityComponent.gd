extends Component
class_name SanityComponent

# Sanity / mental health component for atmospheric horror.
# Low sanity triggers audio/visual distortions via signals.
# Other systems (audio manager, post-processing) listen to these signals.

@export var max_sanity: float = 100.0
@export var drain_rate_dark: float = 5.0      # per second in darkness
@export var drain_rate_monster: float = 20.0  # per second near threat
@export var gain_rate_safe: float = 3.0       # per second in safe light
@export var low_sanity_threshold: float = 30.0

var sanity: float = 100.0
var is_in_darkness: bool = false
var is_near_threat: bool = false
var is_in_safe_zone: bool = false

var _was_low: bool = false
var _was_critical: bool = false
var _was_recovered: bool = false

signal sanity_changed(current: float, max: float)
signal low_sanity_reached()
signal sanity_critical()
signal sanity_recovered()

func _ready() -> void:
	super()
	sanity = max_sanity
	sanity_changed.emit(sanity, max_sanity)
	# Self-register with the global manager so the UI can find this component
	# regardless of the node name or scene layout.
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.set_sanity_component(self)

func _component_process(delta: float) -> void:
	var delta_sanity: float = 0.0

	if is_near_threat:
		delta_sanity -= drain_rate_monster * delta
	elif is_in_darkness:
		delta_sanity -= drain_rate_dark * delta
	elif is_in_safe_zone:
		delta_sanity += gain_rate_safe * delta

	sanity = clamp(sanity + delta_sanity, 0.0, max_sanity)
	sanity_changed.emit(sanity, max_sanity)

	# Threshold signals are edge triggered so listeners are not flooded
	# every frame while the value stays on one side of the threshold.
	var is_critical: bool = sanity <= 10.0
	var is_low: bool = sanity <= low_sanity_threshold
	var is_recovered: bool = sanity >= max_sanity * 0.8 and delta_sanity > 0.0

	if is_critical and not _was_critical:
		sanity_critical.emit()
	_was_critical = is_critical

	if is_low and not _was_low:
		low_sanity_reached.emit()
	_was_low = is_low

	if is_recovered and not _was_recovered:
		sanity_recovered.emit()
	_was_recovered = is_recovered

func set_darkness(value: bool) -> void:
	is_in_darkness = value

func set_near_threat(value: bool) -> void:
	is_near_threat = value

func set_safe_zone(value: bool) -> void:
	is_in_safe_zone = value

func get_sanity_percentage() -> float:
	return sanity / max_sanity * 100.0

func restore_sanity(amount: float) -> void:
	sanity = clamp(sanity + amount, 0, max_sanity)
	sanity_changed.emit(sanity, max_sanity)

func drain_sanity(amount: float) -> void:
	sanity = clamp(sanity - amount, 0, max_sanity)
	sanity_changed.emit(sanity, max_sanity)
