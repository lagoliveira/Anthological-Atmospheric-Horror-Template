extends ProgressBar
class_name SanityBar

# UI sanity bar that reacts to SanityComponent changes.
# Changes color when sanity is low.

@export var low_sanity_color: Color = Color(1, 0.2, 0.2)
@export var normal_color: Color = Color(0.8, 0.8, 0.8)

func _ready() -> void:
	var game_manager: GameManager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	var sanity_component: SanityComponent = get_node_or_null("%SanityComponent") as SanityComponent
	if sanity_component:
		max_value = sanity_component.max_sanity
		set_value(sanity_component.sanity)
		sanity_component.sanity_changed.connect(_on_sanity_changed)

func _on_sanity_changed(current: float, max: float) -> void:
	set_value(current)
	if current / max < 0.3:
		add_theme_color_override("fill_color", low_sanity_color)
	else:
		add_theme_color_override("fill_color", normal_color)
