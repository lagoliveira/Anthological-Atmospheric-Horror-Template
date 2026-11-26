extends CanvasLayer
class_name FadeManager

# Screen fade manager for transitions between chapters/scenes.
# Used heavily in anthology games to separate distinct stories.

@export var fade_color: Color = Color(0, 0, 0, 1)
@export var fade_duration: float = 1.0

var fade_rect: ColorRect
var is_fading: bool = false

signal fade_started()
signal fade_finished()

func _ready() -> void:
	fade_rect = ColorRect.new()
	fade_rect.color = fade_color
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0
	add_child(fade_rect)

func fade_in(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	_fade_to(0.0, duration)

func fade_out(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_duration
	_fade_to(1.0, duration)

func _fade_to(target_alpha: float, duration: float) -> void:
	if is_fading:
		return
	is_fading = true
	fade_started.emit()

	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	tween.tween_callback(func():
		is_fading = false
		fade_finished.emit()
	)

func change_scene_fade(scene_path: String, fade_duration: float = 1.0) -> void:
	fade_out(fade_duration)
	var tween: Tween = create_tween()
	tween.tween_interval(fade_duration)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
		fade_in(fade_duration)
	)
