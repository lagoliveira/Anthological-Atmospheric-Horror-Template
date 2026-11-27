extends ProgressBar
class_name SanityBar

# UI sanity bar that reacts to SanityComponent changes.
# Changes color when sanity is low.

@export var low_sanity_color: Color = Color(1, 0.2, 0.2)
@export var normal_color: Color = Color(0.8, 0.8, 0.8)

func _ready() -> void:
	_bind_to_sanity()
	GameManager.player_registered.connect(_on_player_registered)

func _bind_to_sanity() -> void:
	var sanity_component: SanityComponent = GameManager.get_sanity_component()
	if sanity_component == null:
		return
	max_value = sanity_component.max_sanity
	set_value(sanity_component.sanity)
	if not sanity_component.sanity_changed.is_connected(_on_sanity_changed):
		sanity_component.sanity_changed.connect(_on_sanity_changed)

func _on_player_registered(_player: Node3D) -> void:
	_bind_to_sanity()

func _on_sanity_changed(current: float, max: float) -> void:
	set_value(current)
	if current / max < 0.3:
		add_theme_color_override("fill_color", low_sanity_color)
	else:
		add_theme_color_override("fill_color", normal_color)
