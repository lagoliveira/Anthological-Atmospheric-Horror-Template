extends Node
class_name SaveSystem

# Save/load system using Godot's FileAccess.
# Stores player position, inventory, sanity, and notes state.

@export var save_slot_count: int = 3
@export var save_folder: String = "user://saves/"

var current_save_id: String = "save1"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(save_folder)

func save_game(save_id: String = "", player: Node3D = null, inventory: InventoryManager = null, sanity: SanityComponent = null, notes: NotesManager = null) -> bool:
	var id: String = save_id if save_id != "" else current_save_id
	var file_path: String = get_save_path(id)

	var save_data: Dictionary = {
		"player_position": player.global_position if player else Vector3.ZERO,
		"player_rotation": player.quaternion if player else Quaternion.IDENTITY,
		"sanity": sanity.sanity if sanity else 100.0,
		"inventory": inventory.to_save_data() if inventory else [],
		"notes": notes.get_notes_data() if notes else [],
		"timestamp": Time.get_unix_time_from_system()
	}

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: não foi possível salvar em " + file_path)
		return false

	file.store_var(save_data)
	file.close()
	return true

func load_game(save_id: String = "", player: Node3D = null, inventory: InventoryManager = null, sanity: SanityComponent = null, notes: NotesManager = null) -> Dictionary:
	var id: String = save_id if save_id != "" else current_save_id
	var file_path: String = get_save_path(id)

	if not FileAccess.file_exists(file_path):
		push_warning("SaveSystem: save não encontrado: " + file_path)
		return {}

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("SaveSystem: não foi possível abrir " + file_path)
		return {}

	var data: Dictionary = file.get_var()
	file.close()

	if player:
		player.global_position = data.get("player_position", Vector3.ZERO)
		player.quaternion = data.get("player_rotation", Quaternion.IDENTITY)
	if sanity:
		sanity.sanity = data.get("sanity", 100.0)
		sanity.sanity_changed.emit(sanity.sanity, sanity.max_sanity)
	if inventory and data.has("inventory"):
		inventory.from_save_data(data.get("inventory", []))
	if notes and data.has("notes"):
		notes.load_notes_data(data.get("notes", []))

	return data

func get_save_path(save_id: String) -> String:
	return save_folder + save_id + ".save"

# Returns the save slot identifiers (without the file extension), so the
# values can be passed directly to load_game() and delete_save().
func get_save_list() -> Array:
	var files: Array = []
	var dir: DirAccess = DirAccess.open(save_folder)
	if not dir:
		return files
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			files.append(file_name.trim_suffix(".save"))
		file_name = dir.get_next()
	dir.list_dir_end()
	return files

# Returns the metadata of every save slot, newest first.
func get_save_slots() -> Array:
	var slots: Array = []
	for save_id: String in get_save_list():
		var file_path: String = get_save_path(save_id)
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			continue
		var data: Dictionary = file.get_var()
		file.close()
		slots.append({
			"id": save_id,
			"timestamp": data.get("timestamp", 0),
			"sanity": data.get("sanity", 100.0),
			"item_count": data.get("inventory", []).size(),
			"note_count": data.get("notes", []).size()
		})
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("timestamp", 0.0) > b.get("timestamp", 0.0))
	return slots

func has_save(save_id: String) -> bool:
	return FileAccess.file_exists(get_save_path(save_id))

func delete_save(save_id: String) -> bool:
	var file_path: String = get_save_path(save_id)
	if not FileAccess.file_exists(file_path):
		return false
	var d: DirAccess = DirAccess.open(save_folder)
	if not d:
		return false
	var err: Error = d.remove(file_path)
	return err == Error.OK
