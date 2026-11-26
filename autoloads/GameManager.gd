extends Node
class_name GameManager

# Central autoload that holds references to all global managers
# and provides high-level game state for the anthology template.

@onready var save_system: SaveSystem = get_node("SaveSystem")
@onready var audio_manager: AudioManager = get_node("AudioManager")
@onready var fade_manager: FadeManager = get_node("FadeManager")
@onready var notes_manager: NotesManager = get_node("NotesManager")
@onready var inventory_manager: InventoryManager = get_node("InventoryManager")

var current_chapter: String = ""
var is_paused: bool = false
var player: Node3D

signal chapter_changed(new_chapter: String)
signal game_paused(is_paused: bool)
signal sanity_restored(amount: float)

func _ready() -> void:
	# Ensure managers exist
	if not save_system:
		push_error("GameManager: SaveSystem não encontrado!")
	if not audio_manager:
		push_error("GameManager: AudioManager não encontrado!")
	if not fade_manager:
		push_error("GameManager: FadeManager não encontrado!")
	if not notes_manager:
		push_error("GameManager: NotesManager não encontrado!")
	if not inventory_manager:
		push_error("GameManager: InventoryManager não encontrado!")

func set_player(new_player: Node3D) -> void:
	player = new_player

func restore_sanity(amount: float) -> void:
	var sanity_component: SanityComponent = get_node_or_null("%SanityComponent") as SanityComponent
	if not sanity_component and player:
		sanity_component = player.get_node_or_null("SanityComponent") as SanityComponent
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
