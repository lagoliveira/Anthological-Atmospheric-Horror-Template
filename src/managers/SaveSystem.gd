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
	var file_path: String = save_folder + id + ".save"

	var save_data: Dictionary = {
		"player_position": player.global_position if player else Vector3.ZERO,
		"player_rotation": player.rotation_quaternion if player else Quat.IDENTITY,
		"sanity": sanity.sanity if sanity else 100.0,
		"inventory": inventory.get_all_items() if inventory else {},
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
	var file_path: String = save_folder + id + ".save"

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("SaveSystem: save não encontrado: " + file_path)
		return {}

	var data: Dictionary = file.get_var()
	file.close()

	if player:
		player.global_position = data.get("player_position", Vector3.ZERO)
		player.rotation_quaternion = data.get("player_rotation", Quat.IDENTITY)
	if sanity:
		sanity.sanity = data.get("sanity", 100.0)
		sanity.sanity_changed.emit(sanity.sanity, sanity.max_sanity)
	if inventory and data.has("inventory"):
		# inventory is a Dictionary {id: {item, count}} - we need InventoryItem resources
		pass
	if notes and data.has("notes"):
		notes.load_notes_data(data.get("notes", []))

	return data

func get_save_list() -> Array:
	var files: Array = []
	var dir: DirAccess = DirAccess.open(save_folder)
	if not dir:
		return files
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			files.append(file_name)
		file_name = dir.get_next()
	return files

func delete_save(save_id: String) -> bool:
	var file_path: String = save_folder + save_id + ".save"
	return DirAccess.remove_file_absolute(file_path)
