extends TextureRect
class_name Crosshair

# Simple crosshair UI for first-person view.
# Reacts to sanity: wobbles/dims when sanity is low.

@export var crosshair_texture: Texture2D
@export var low_sanity_wobble: bool = true
@export var wobble_amount: float = 4.0
@export var low_sanity_threshold: float = 30.0

var wobble_timer: float = 0.0

var _base_left: float = 0.0
var _base_right: float = 0.0

func _ready() -> void:
	if crosshair_texture:
		texture = crosshair_texture

	# The control size is not resolved yet when _ready() runs, so the base
	# offsets are derived from the texture instead of from `size`.
	var icon_size: Vector2 = Vector2(32, 32)
	if texture and texture.get_size().x > 0.0 and texture.get_size().y > 0.0:
		icon_size = texture.get_size()

	_base_left = -icon_size.x * 0.5
	_base_right = icon_size.x * 0.5
	offset_left = _base_left
	offset_right = _base_right
	offset_top = -icon_size.y * 0.5
	offset_bottom = icon_size.y * 0.5

func _process(delta: float) -> void:
	var sanity_component: SanityComponent = GameManager.get_sanity_component()
	if not sanity_component:
		return

	var sanity_pct: float = sanity_component.get_sanity_percentage()
	if low_sanity_wobble and sanity_pct < low_sanity_threshold:
		wobble_timer += delta
		var factor: float = 1.0 - sanity_pct / low_sanity_threshold
		var offset: float = sin(wobble_timer * 8.0) * wobble_amount * factor
		offset_left = _base_left + offset
		offset_right = _base_right + offset
		modulate.a = lerp(1.0, 0.5, factor)
	else:
		# Restore the base position, otherwise the wobble stays applied.
		offset_left = _base_left
		offset_right = _base_right
		modulate.a = 1.0
