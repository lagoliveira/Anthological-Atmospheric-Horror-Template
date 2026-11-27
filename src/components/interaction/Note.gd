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

	GameManager.get_notes_manager().add_note(note_id, note_title, note_text, note_texture)

	if audio_on_read:
		GameManager.get_audio_manager().play_sound(audio_on_read)

	GameManager.restore_sanity(sanity_gain)

	# The base class already emits `interacted` after _interact() returns.
	queue_free()
