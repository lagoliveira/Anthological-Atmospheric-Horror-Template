extends Node
class_name NotesManager

# Tracks collected lore notes for the anthology.
# Each chapter can add its own notes; persisted across saves.

var notes: Dictionary = {}  # note_id -> {title, text, texture, read_at}

signal note_added(note_id: String, title: String)
signal notes_list_changed()

func add_note(note_id: String, title: String, text: String = "", texture: Texture2D = null) -> void:
	if notes.has(note_id):
		return
	notes[note_id] = {
		"title": title,
		"text": text,
		"texture": texture,
		"read_at": Time.get_datetime_string_from_system()
	}
	note_added.emit(note_id, title)
	notes_list_changed.emit()

func has_note(note_id: String) -> bool:
	return notes.has(note_id)

func get_note(note_id: String) -> Dictionary:
	return notes.get(note_id, {})

func get_notes_data() -> Array:
	var data: Array = []
	for id in notes.keys():
		data.append({
			"id": id,
			"title": notes[id]["title"],
			"text": notes[id]["text"],
			"read_at": notes[id]["read_at"]
		})
	return data

func load_notes_data(data: Array) -> void:
	notes.clear()
	for entry in data:
		var id: String = entry.get("id", "")
		if id != "":
			notes[id] = {
				"title": entry.get("title", ""),
				"text": entry.get("text", ""),
				"texture": null,
				"read_at": entry.get("read_at", "")
			}
	notes_list_changed.emit()

func get_note_count() -> int:
	return notes.size()

func clear() -> void:
	notes.clear()
	notes_list_changed.emit()
