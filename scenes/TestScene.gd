extends Node3D

# Test scene controller.
# Wires the template components together so they can be validated end to end:
# the dark zone drains player sanity, the lamp feeds the flashlight state and
# the HUD reacts to the sanity component.

@onready var dark_zone: TriggerZone = get_node_or_null("DarkZone/DarkZoneComponent")
@onready var lamp: LightSource = get_node_or_null("LampLight/LampComponent")
@onready var player: Node3D = get_node_or_null("Player")
@onready var prompt_label: Label = get_node_or_null("HUD/InteractionPrompt")

func _ready() -> void:
	if dark_zone:
		dark_zone.zone_entered.connect(_on_zone_entered)
		dark_zone.zone_exited.connect(_on_zone_exited)

	if player:
		var interaction_manager: InteractionManager = player.get_node_or_null("InteractionManager")
		if interaction_manager:
			interaction_manager.target_changed.connect(_on_target_changed)

func _on_target_changed(target: Interactable) -> void:
	if prompt_label == null:
		return
	if target:
		prompt_label.text = "[E]  %s" % target.get_prompt()
	else:
		prompt_label.text = ""

func _get_sanity() -> SanityComponent:
	return GameManager.get_sanity_component()

func _on_zone_entered(_body: Node) -> void:
	var sanity: SanityComponent = _get_sanity()
	if sanity:
		sanity.set_darkness(true)

func _on_zone_exited(_body: Node) -> void:
	var sanity: SanityComponent = _get_sanity()
	if sanity:
		sanity.set_darkness(false)
