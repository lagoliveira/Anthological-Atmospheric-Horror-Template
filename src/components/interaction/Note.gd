extends Interactable
class_name Note

# Collectable lore note for environmental storytelling.
# When interacted, adds to NotesManager and shows the note text.

@export var note_id: String = ""
@export var note_title: String = "Nota"
@export var note_text: String = ""
@export var note_texture: Texture2D  # optional handwritten note image
@export var audio_on_read: AudioStream
@export var sanity_gain: float = 5.0

var is_read: bool = false

func _ready() -> void:
	interaction_prompt = "Ler nota"

func _interact(interactor: Node) -> void:
	if is_read:
		return
	is_read = true
	is_interactable = false

	var notes_manager: NotesManager = get_node_or_null("/root/NotesManager")
	if notes_manager:
		notes_manager.add_note(note_id, note_title, note_text, note_texture)

	if audio_on_read:
		var audio_manager: AudioManager = get_node_or_null("/root/AudioManager")
		if audio_manager:
			audio_manager.play_sound(audio_on_read)

	var game_manager: GameManager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.restore_sanity(sanity_gain)

	interacted.emit(interactor)
	queue_free()
