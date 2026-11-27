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
	_apply_loop()

	if not play_on_start:
		return

	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout
		# The node may have left the tree while waiting for the delay.
		if not is_inside_tree():
			return

	play_one_shot()

# Looping is a property of the stream, not of the player, and every stream
# type exposes it differently.
func _apply_loop() -> void:
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop

func play_one_shot() -> void:
	if random_pitch:
		pitch_scale = 1.0 + (randf() - 0.5) * pitch_variation
	play()

func stop_sound() -> void:
	stop()
