extends AudioStreamPlayer3D
class_name AudioEmitter

# Positional audio emitter for environmental sounds.
# Supports looping, random pitch variation, and distance-based attenuation.

@export var play_on_start: bool = false
@export var loop: bool = false
@export var random_pitch: bool = false
@export var pitch_variation: float = 0.1
@export var start_delay: float = 0.0

func _ready() -> void:
	stream_paused = false
	autoplay = play_on_start
	loop = loop

	if play_on_start and start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
		play()

func play_one_shot() -> void:
	if random_pitch:
		pitch_scale = 1.0 + (randf() - 0.5) * pitch_variation
	play()

func stop_sound() -> void:
	stop()
