extends Area3D
class_name Interactable

# Base class for anything the player can interact with.
# Subclasses override _interact() to define behavior.
# Extends Area3D so the InteractionManager ray query can detect it.
# Add a CollisionShape3D child to define the interaction volume.

@export var interaction_distance: float = 3.0
@export var interaction_prompt: String = "Interagir"
@export var highlight_on_look: bool = true
@export var highlight_color: Color = Color(1, 1, 1, 0.3)

var is_interactable: bool = true
var is_highlighted: bool = false

signal interacted(interactor: Node)
signal prompted(prompt: String)
signal prompt_removed()

var _highlight_material: StandardMaterial3D = null

func interact(interactor: Node) -> void:
	if not is_interactable:
		return
	_interact(interactor)
	interacted.emit(interactor)

func _interact(interactor: Node) -> void:
	# Override in subclasses
	pass

func set_highlight(enabled: bool) -> void:
	if is_highlighted == enabled:
		return
	is_highlighted = enabled
	_apply_highlight(enabled and highlight_on_look)
	if enabled:
		prompted.emit(interaction_prompt)
	else:
		prompt_removed.emit()

func _apply_highlight(enabled: bool) -> void:
	for mesh: MeshInstance3D in get_highlight_meshes():
		if enabled:
			mesh.material_overlay = _get_highlight_material()
		else:
			mesh.material_overlay = null

func _get_highlight_material() -> StandardMaterial3D:
	if _highlight_material == null:
		_highlight_material = StandardMaterial3D.new()
		_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_highlight_material.albedo_color = highlight_color
	_highlight_material.albedo_color = highlight_color
	return _highlight_material

# Finds the visual meshes that represent this interactable. The mesh usually
# lives as a sibling of the component (the component owns the behaviour, the
# mesh owns the look), so both levels are searched.
func get_highlight_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var host: Node = get_parent()
	if host:
		for child: Node in host.get_children():
			var mesh: MeshInstance3D = child as MeshInstance3D
			if mesh:
				meshes.append(mesh)
	for child: Node in get_children():
		var mesh: MeshInstance3D = child as MeshInstance3D
		if mesh:
			meshes.append(mesh)
	return meshes

func get_prompt() -> String:
	return interaction_prompt

func is_available() -> bool:
	return is_interactable
