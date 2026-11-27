extends Node

# Central autoload that owns every global manager and exposes
# high-level game state for the anthology template.
#
# The managers are created in code as children of this node so that
# there is a single autoload entry to configure in Project Settings.
#
# NOTE: this script intentionally has no `class_name`. An autoload singleton
# already occupies the global identifier "GameManager", and declaring a class
# with the same name raises "Class hides an autoload singleton".
# Access it from other scripts directly as the global `GameManager`.

var save_system: SaveSystem
var audio_manager: AudioManager
var fade_manager: FadeManager
var notes_manager: NotesManager
var inventory_manager: InventoryManager

var current_chapter: String = ""
var is_paused: bool = false
var player: Node3D
var sanity_component: SanityComponent

signal chapter_changed(new_chapter: String)
signal game_paused(is_paused: bool)
signal sanity_restored(amount: float)
signal player_registered(player: Node3D)

func _ready() -> void:
	save_system = SaveSystem.new()
	save_system.name = "SaveSystem"
	add_child(save_system)

	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

	fade_manager = FadeManager.new()
	fade_manager.name = "FadeManager"
	add_child(fade_manager)

	notes_manager = NotesManager.new()
	notes_manager.name = "NotesManager"
	add_child(notes_manager)

	inventory_manager = InventoryManager.new()
	inventory_manager.name = "InventoryManager"
	add_child(inventory_manager)

	# The player may not exist yet at autoload time, so discovery is retried
	# every frame until one is found.
	set_process(true)

func _process(_delta: float) -> void:
	if player == null:
		_discover_player()

func _discover_player() -> void:
	# Fallback for players that do not use the InteractionManager component.
	var candidates: Array[Node] = get_tree().get_nodes_in_group("Player")
	for candidate in candidates:
		var node_3d: Node3D = candidate as Node3D
		if node_3d:
			set_player(node_3d)
			return

func set_player(new_player: Node3D) -> void:
	if new_player == null:
		return
	player = new_player

	# Look for the sanity component anywhere in the player subtree so the
	# component does not depend on a specific node name.
	var found: SanityComponent = _find_sanity_component(new_player)
	if found:
		sanity_component = found

	player_registered.emit(new_player)

func _find_sanity_component(root: Node) -> SanityComponent:
	if root == null:
		return null
	var direct: SanityComponent = root.get_node_or_null("SanityComponent") as SanityComponent
	if direct:
		return direct
	var children: Array[Node] = root.find_children("*", "SanityComponent", true, false)
	if children.is_empty():
		return null
	return children[0] as SanityComponent

func set_sanity_component(component: SanityComponent) -> void:
	sanity_component = component

func get_sanity_component() -> SanityComponent:
	return sanity_component

func restore_sanity(amount: float) -> void:
	if sanity_component:
		sanity_component.restore_sanity(amount)
	sanity_restored.emit(amount)

func switch_chapter(chapter_name: String, scene_path: String) -> void:
	current_chapter = chapter_name
	chapter_changed.emit(chapter_name)
	fade_manager.change_scene_fade(scene_path, 1.0)

func pause_game(pause: bool) -> void:
	is_paused = pause
	get_tree().paused = pause
	game_paused.emit(pause)

func get_save_system() -> SaveSystem:
	return save_system

func get_audio_manager() -> AudioManager:
	return audio_manager

func get_fade_manager() -> FadeManager:
	return fade_manager

func get_notes_manager() -> NotesManager:
	return notes_manager

func get_inventory_manager() -> InventoryManager:
	return inventory_manager
