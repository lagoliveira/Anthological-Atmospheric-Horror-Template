extends Node

# Functional self-check for the template.
#
# Run it from the editor (F6 on this scene) or from the command line:
#   godot --headless --path . res://tests/functional_test.tscn
#
# The scene exits with code 0 when every check passes and with code 1 when
# at least one check fails, so it can be used in CI.

var failures: Array[String] = []
var passes: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_run()

func check(condition: bool, label: String) -> void:
	if condition:
		passes += 1
		print("PASS | " + label)
	else:
		failures.append(label)
		print("FAIL | " + label)

func _run() -> void:
	var gm: Node = get_node("/root/GameManager")
	check(gm != null, "GameManager autoload existe")
	check(gm.get_inventory_manager() != null, "InventoryManager criado")
	check(gm.get_audio_manager() != null, "AudioManager criado")
	check(gm.get_fade_manager() != null, "FadeManager criado")
	check(gm.get_notes_manager() != null, "NotesManager criado")
	check(gm.get_save_system() != null, "SaveSystem criado")

	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var player: Node3D = player_scene.instantiate()
	add_child(player)
	await get_tree().process_frame

	check(player.is_in_group("Player"), "Player no grupo 'Player'")
	check(player.get_node_or_null("SanityComponent") != null, "SanityComponent presente")
	check(player.get_node_or_null("FlashlightComponent") != null, "FlashlightComponent presente")
	check(player.get_node_or_null("InteractionManager") != null, "InteractionManager presente")
	check(player.get_node_or_null("CameraPivot/Camera") != null, "Camera presente")
	check(player.get_node_or_null("CollisionShape3D") != null, "Colisao presente")

	var test_scene: PackedScene = load("res://scenes/TestScene.tscn")
	var ts: Node = test_scene.instantiate()
	add_child(ts)
	await get_tree().process_frame

	var dz: TriggerZone = ts.get_node_or_null("DarkZone")
	check(dz != null, "DarkZone e TriggerZone")
	check(dz.get_node_or_null("DarkZoneShape") != null, "DarkZoneShape presente")

	var lamp: LightSource = ts.get_node_or_null("LampLight/LampComponent")
	check(lamp != null, "LampComponent e LightSource")
	check(lamp.light_node != null, "LampComponent.light_node resolvido")
	check(lamp.light_node is OmniLight3D, "LampComponent.light_node e OmniLight3D")

	var door: Door = ts.get_node_or_null("TestDoor/DoorComponent")
	check(door != null, "DoorComponent e Door")
	check(door.door_node != null, "DoorComponent.door_node resolvido")

	var note: Note = ts.get_node_or_null("TestNote/NoteComponent")
	check(note != null, "NoteComponent e Note")

	check(ts.get_node_or_null("HUD/Crosshair") != null, "Crosshair na HUD")
	check(ts.get_node_or_null("HUD/SanityBar") != null, "SanityBar na HUD")
	check(ts.get_node_or_null("HUD/InteractionPrompt") != null, "InteractionPrompt na HUD")

	# --- Raycast de interacao ---
	player.global_position = Vector3(0, 0, -6)
	var cam_pivot: Node3D = player.get_node_or_null("CameraPivot")
	cam_pivot.rotation.x = deg_to_rad(-10)
	var im: InteractionManager = player.get_node_or_null("InteractionManager")
	for i in 6:
		await get_tree().physics_frame
	check(im.current_target == door, "Raycast encontrou a porta (current_target == Door)")

	# --- Highlight do alvo ---
	var door_mesh: MeshInstance3D = ts.get_node_or_null("TestDoor/DoorMesh")
	check(door_mesh != null, "DoorMesh encontrado")
	check(door_mesh.material_overlay != null, "Highlight aplicou material_overlay na malha")
	# Move away so the raycast actually loses the target.
	player.global_position = Vector3(0, 0, 6)
	for i in 4:
		await get_tree().physics_frame
	check(im.current_target == null, "Alvo perdido apos sair do alcance")
	check(door_mesh.material_overlay == null, "Highlight removido ao perder o alvo")
	player.global_position = Vector3(0, 0, -6)
	for i in 4:
		await get_tree().physics_frame
	check(im.current_target == door, "Alvo reencontrado ao voltar")

	# --- Eco de teclado ---
	var open_before: bool = door.is_open
	var echo_event: InputEventKey = InputEventKey.new()
	echo_event.keycode = KEY_E
	echo_event.physical_keycode = KEY_E
	echo_event.pressed = true
	echo_event.echo = true
	im._unhandled_input(echo_event)
	await get_tree().process_frame
	check(door.is_open == open_before, "Eco de teclado nao ativa interacao")

	var press_event: InputEventKey = InputEventKey.new()
	press_event.keycode = KEY_E
	press_event.physical_keycode = KEY_E
	press_event.pressed = true
	press_event.echo = false
	im._unhandled_input(press_event)
	await get_tree().process_frame
	check(door.is_open != open_before, "Tecla normal ativa interacao")

	# --- interaction_distance ---
	door.interaction_distance = 0.5
	im._update_target()
	await get_tree().physics_frame
	check(im.current_target == null, "interaction_distance respeitada (alvo longe descartado)")
	door.interaction_distance = 3.0
	im._update_target()
	await get_tree().physics_frame
	check(im.current_target == door, "interaction_distance restaurada (alvo reencontrado)")

	# --- Interacao com a porta ---
	door.interact(player)
	await get_tree().process_frame
	check(door.is_open != open_before, "Porta alterna estado ao interagir")

	# --- Nota ---
	var nm: NotesManager = gm.get_notes_manager()
	var count_before: int = nm.get_note_count()
	note.interact(player)
	await get_tree().process_frame
	check(nm.get_note_count() == count_before + 1, "Nota registrada no NotesManager")
	check(nm.has_note("intro_note_01"), "Nota intro_note_01 presente")

	# --- Alvo destruido ---
	for i in 6:
		await get_tree().physics_frame
	check(is_instance_valid(im.current_target), "current_target nunca aponta para objeto liberado")

	# --- Inventario ---
	var inv: InventoryManager = gm.get_inventory_manager()
	var item: InventoryItem = InventoryItem.new()
	item.item_id = "chave_teste"
	item.item_name = "Chave de Teste"
	item.item_description = "Uma chave usada no teste"
	inv.add_item(item, 1)
	check(inv.has_item("chave_teste"), "Item adicionado ao inventario")
	check(inv.get_item_count("chave_teste") == 1, "Contagem de item correta")
	inv.remove_item("chave_teste")
	check(not inv.has_item("chave_teste"), "Item removido do inventario")

	# --- Copia independente do inventario ---
	item.item_id = "item_compartilhado"
	inv.add_item(item, 2)
	var snapshot: Dictionary = inv.get_all_items()
	inv.remove_item("item_compartilhado", 1)
	check(snapshot["item_compartilhado"]["count"] == 2, "get_all_items devolve copia independente")

	# --- Save / Load ---
	var ss: SaveSystem = gm.get_save_system()
	var sanity_comp: SanityComponent = player.get_node_or_null("SanityComponent")
	var ok: bool = ss.save_game("test_slot", player, inv, sanity_comp, nm)
	check(ok, "SaveSystem salvou")
	inv.clear()
	check(inv.get_item_count("item_compartilhado") == 0, "Inventario limpo antes do load")
	var data: Dictionary = ss.load_game("test_slot", player, inv, sanity_comp, nm)
	check(not data.is_empty(), "SaveSystem carregou dados")
	check(data.has("player_position"), "Save contem player_position")
	check(data.has("sanity"), "Save contem sanity")

	# --- Restauracao do inventario ---
	check(inv.has_item("item_compartilhado"), "Inventario restaurado apos load")
	check(inv.get_item_count("item_compartilhado") == 1, "Contagem do item restaurada apos load")
	var restored: InventoryItem = inv.get_item("item_compartilhado")
	check(restored != null, "InventoryItem reconstruido apos load")
	if restored:
		check(restored.item_name == "Chave de Teste", "Metadados do item preservados no load")
		check(restored.item_description == "Uma chave usada no teste", "Descricao do item preservada no load")

	# --- API dos slots ---
	var save_list: Array = ss.get_save_list()
	check(save_list.has("test_slot"), "get_save_list devolve identificadores de slot")
	check(ss.has_save("test_slot"), "has_save detecta o slot")
	var slots: Array = ss.get_save_slots()
	check(slots.size() == 1, "get_save_slots devolve metadados")
	ss.delete_save("test_slot")
	check(ss.get_save_list().is_empty(), "Save removido do disco")

	# --- Sanidade ---
	var sanity: SanityComponent = gm.get_sanity_component()
	var s0: float = sanity.sanity
	sanity.set_darkness(true)
	await get_tree().create_timer(0.3).timeout
	check(sanity.sanity < s0, "Sanidade cai na escuridao")
	sanity.set_darkness(false)
	sanity.restore_sanity(50)
	check(sanity.sanity > 0, "Sanidade restaurada")

	# --- Limiares de sanidade ---
	var critical_fired: Array[bool] = [false]
	var low_fired: Array[bool] = [false]
	sanity.sanity_critical.connect(func() -> void: critical_fired[0] = true)
	sanity.low_sanity_reached.connect(func() -> void: low_fired[0] = true)
	sanity.sanity = 5.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(critical_fired[0], "sanity_critical e emitido ao cruzar o limiar")
	check(low_fired[0], "low_sanity_reached e emitido ao cruzar o limiar")

	var low_count: Array[int] = [0]
	sanity.low_sanity_reached.connect(func() -> void: low_count[0] += 1)
	for i in 5:
		await get_tree().process_frame
	check(low_count[0] == 0, "Sinais de limiar nao sao repetidos a cada frame")

	# --- Lanterna ---
	var fl: Flashlight = player.get_node_or_null("FlashlightComponent")
	check(fl != null, "FlashlightComponent e Flashlight")
	fl.toggle()
	check(fl.is_on, "Lanterna ligou")
	check(fl.light_node.visible, "SpotLight3D da lanterna visivel")
	fl.toggle()
	check(not fl.is_on, "Lanterna desligou")

	# --- Esgotamento da bateria ---
	var depleted_fired: Array[bool] = [false]
	fl.battery_depleted.connect(func() -> void: depleted_fired[0] = true)
	fl.battery = 0.1
	fl.is_on = true
	fl.light_node.visible = true
	await get_tree().create_timer(0.3).timeout
	check(depleted_fired[0], "Sinal battery_depleted emitido ao esgotar")
	check(not fl.is_on, "Lanterna desligou ao esgotar a bateria")
	check(not fl.light_node.visible, "Luz da lanterna apagada ao esgotar a bateria")
	check(not fl.is_flickering, "Flicker interrompido ao esgotar a bateria")

	# --- Fade ---
	var fm: FadeManager = gm.get_fade_manager()
	check(fm.fade_rect != null, "FadeManager criou ColorRect")
	check(fm.layer > 1, "FadeManager acima da camada da HUD")
	fm.fade_out(0.05)
	await get_tree().create_timer(0.2).timeout
	check(fm.fade_rect.modulate.a > 0.5, "Fade out aplicou alpha")
	fm.fade_in(0.05)
	await get_tree().create_timer(0.2).timeout
	check(fm.fade_rect.modulate.a < 0.5, "Fade in restaurou alpha")

	# --- Audio ---
	var am: AudioManager = gm.get_audio_manager()
	am.play_sound(null)
	am.set_ambient(null)
	am.set_sanity_multiplier(0.5)
	check(true, "AudioManager tolerou streams nulos")

	# --- Movimento planar ---
	var fp: FPController = player.get_node_or_null(".")
	fp.camera_pivot.rotation.x = deg_to_rad(-45)
	var dir: Vector3 = fp._get_move_direction(Vector2(0, 1))
	check(absf(dir.y) < 0.0001, "Direcao de movimento planar (sem componente vertical)")
	fp.camera_pivot.rotation.x = 0.0

	# --- Rotacao da camera com o analogico direito ---
	check(InputMap.has_action("look_left"), "Acao look_left existe no InputMap")
	check(InputMap.has_action("look_right"), "Acao look_right existe no InputMap")
	check(InputMap.has_action("look_up"), "Acao look_up existe no InputMap")
	check(InputMap.has_action("look_down"), "Acao look_down existe no InputMap")

	var right_axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
	right_axis.device = 0
	right_axis.axis = JOY_AXIS_RIGHT_X
	right_axis.axis_value = 1.0
	Input.parse_input_event(right_axis)
	await get_tree().process_frame
	await get_tree().process_frame
	check(fp.yaw < 0.0, "Analogico direito para a direita gira a camera para a direita")
	check(is_equal_approx(fp.camera_pivot.rotation.y, fp.yaw), "Rotacao do analogico aplicada no CameraPivot")

	right_axis.axis_value = 0.0
	Input.parse_input_event(right_axis)
	await get_tree().process_frame
	await get_tree().process_frame
	var yaw_rest: float = fp.yaw

	# Deadzone: uma deflexao pequena nao deve girar a camera.
	right_axis.axis_value = 0.1
	Input.parse_input_event(right_axis)
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_equal_approx(fp.yaw, yaw_rest), "Deadzone do analogico ignora deflexoes pequenas")
	right_axis.axis_value = 0.0
	Input.parse_input_event(right_axis)
	await get_tree().process_frame
	await get_tree().process_frame

	var up_axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
	up_axis.device = 0
	up_axis.axis = JOY_AXIS_RIGHT_Y
	up_axis.axis_value = -1.0
	Input.parse_input_event(up_axis)
	await get_tree().process_frame
	await get_tree().process_frame
	check(fp.pitch > 0.0, "Analogico direito para cima olha para cima")
	up_axis.axis_value = 0.0
	Input.parse_input_event(up_axis)
	await get_tree().process_frame
	await get_tree().process_frame

	# --- Registro do jogador ---
	var registered: Array[bool] = [false]
	gm.player_registered.connect(func(_p: Node3D) -> void: registered[0] = true)
	gm.set_player(player)
	await get_tree().process_frame
	check(registered[0], "player_registered e emitido sempre")

	# --- Crosshair ---
	var crosshair: Crosshair = ts.get_node_or_null("HUD/Crosshair")
	check(crosshair.offset_right > 0.0, "Crosshair nao foi colapsado para tamanho zero")
	check(crosshair.offset_left < 0.0, "Crosshair centralizado horizontalmente")

	print("=== RESULTADO: %d passaram, %d falharam ===" % [passes, failures.size()])
	for f in failures:
		print("   FALHOU: " + f)
	get_tree().quit(1 if failures.size() > 0 else 0)
