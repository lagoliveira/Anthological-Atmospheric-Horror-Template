extends Node3D

# Test scene controller.
# Wires the template components together so they can be validated end to end:
# the dark zone drains player sanity, the lamp feeds the flashlight state and
# the HUD reacts to the sanity component.

@onready var dark_zone: TriggerZone = get_node_or_null("DarkZone") as TriggerZone
@onready var lamp: LightSource = get_node_or_null("LampLight/LampComponent") as LightSource
@onready var player: Node3D = get_node_or_null("Player") as Node3D
@onready var prompt_label: Label = get_node_or_null("HUD/InteractionPrompt") as Label

func _ready() -> void:
	if dark_zone:
		dark_zone.zone_entered.connect(_on_zone_entered)
		dark_zone.zone_exited.connect(_on_zone_exited)

	if lamp:
		lamp.light_toggled.connect(_on_lamp_toggled)
		if lamp.affects_sanity:
			_apply_lamp_sanity(lamp.is_lit())

	if player:
		var interaction_manager: InteractionManager = player.get_node_or_null("InteractionManager") as InteractionManager
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

func _on_lamp_toggled(is_on: bool) -> void:
	if lamp and lamp.affects_sanity:
		_apply_lamp_sanity(is_on)

func _apply_lamp_sanity(is_on: bool) -> void:
	var sanity: SanityComponent = _get_sanity()
	if sanity:
		sanity.set_safe_zone(is_on)
