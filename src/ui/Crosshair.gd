extends TextureRect
class_name Crosshair

# Simple crosshair UI for first-person view.
# Reacts to sanity: wobbles/dims when sanity is low.

@export var crosshair_texture: Texture2D
@export var low_sanity_wobble: bool = true
@export var wobble_amount: float = 4.0

var wobble_timer: float = 0.0

func _ready() -> void:
	if crosshair_texture:
		texture = crosshair_texture
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -size.x / 2
	offset_right = size.x / 2
	offset_top = -size.y / 2
	offset_bottom = size.y / 2

func _process(delta: float) -> void:
	var game_manager: GameManager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	var sanity_component: SanityComponent = game_manager.get_sanity_component()
	if not sanity_component:
		return

	var sanity_pct: float = sanity_component.get_sanity_percentage()
	if low_sanity_wobble and sanity_pct < 30.0:
		wobble_timer += delta
		var offset: float = sin(wobble_timer * 8.0) * wobble_amount * (1.0 - sanity_pct / 30.0)
		offset_left = -size.x / 2 + offset
		offset_right = size.x / 2 + offset
		modulate.a = lerp(1.0, 0.5, 1.0 - sanity_pct / 30.0)
	else:
		modulate.a = 1.0
