extends Node
class_name AudioManager

# Global audio manager for atmospheric horror.
# Plays one-shot sounds, manages ambient layers, and reacts to sanity state.

@export var music_bus: AudioStreamPlayer
@export var sfx_bus: AudioStreamPlayer
@export var ambient_bus: AudioStreamPlayer

var current_ambient: AudioStream
var sanity_multiplier: float = 1.0

signal ambient_changed(stream: AudioStream)
signal sanity_level_changed(level: float)

func _ready() -> void:
	if not music_bus:
		music_bus = AudioStreamPlayer.new()
		music_bus.name = "MusicBus"
		add_child(music_bus)
	if not sfx_bus:
		sfx_bus = AudioStreamPlayer.new()
		sfx_bus.name = "SfxBus"
		add_child(sfx_bus)
	if not ambient_bus:
		ambient_bus = AudioStreamPlayer.new()
		ambient_bus.name = "AmbientBus"
		add_child(ambient_bus)

# `volume` is a linear gain (1.0 = full volume) and is converted to the
# decibel scale expected by AudioStreamPlayer.
func play_sound(stream: AudioStream, volume: float = 1.0, pitch: float = 1.0) -> void:
	if not stream:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _gain_to_db(volume)
	player.pitch_scale = pitch
	add_child(player)
	# The connection must exist before playing, otherwise a very short sound
	# could finish before the cleanup is wired.
	player.finished.connect(player.queue_free)
	player.play()

func play_sound_3d(stream: AudioStream, position: Vector3, volume: float = 1.0, pitch: float = 1.0) -> void:
	if not stream:
		return
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = _gain_to_db(volume)
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	# global_position can only be used once the node is inside the tree.
	player.global_position = position
	player.play()

func set_ambient(stream: AudioStream, fade_seconds: float = 2.0) -> void:
	current_ambient = stream
	if ambient_bus:
		ambient_bus.stream = stream
		if stream:
			ambient_bus.play()
		else:
			ambient_bus.stop()
	ambient_changed.emit(stream)

func set_sanity_multiplier(level: float) -> void:
	# level: 0.0 (critical) to 1.0 (healthy)
	sanity_multiplier = clamp(level, 0.0, 1.0)
	sanity_level_changed.emit(sanity_multiplier)

	# Lower sanity -> more distorted ambient pitch
	if ambient_bus:
		ambient_bus.pitch_scale = lerp(1.0, 0.85, 1.0 - sanity_multiplier)

func stop_ambient() -> void:
	if ambient_bus:
		ambient_bus.stop()

func _gain_to_db(gain: float) -> float:
	if gain <= 0.0:
		return -80.0
	return linear_to_db(clamp(gain, 0.0, 1.0))
