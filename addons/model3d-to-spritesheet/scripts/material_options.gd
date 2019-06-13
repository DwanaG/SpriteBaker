tool
extends OptionButton

signal material_changed
signal material_param_changed

const Tools: Script = preload("tools.gd")

export(NodePath) var custom_material_path: NodePath
export(NodePath) var plain_colors_path: NodePath
export(PackedScene) var material_params_scn: PackedScene
export(PackedScene) var plain_item_scn: PackedScene
export(SpatialMaterial) var plain_material: SpatialMaterial
export(SpatialMaterial) var default_material: SpatialMaterial

onready var custom_mat_node: Control = get_node(custom_material_path)
onready var plain_colors: GridContainer = get_node(plain_colors_path)
onready var custom_mat: Material

var plain_mat_dict: Dictionary = {}

var nmaterials: int = 0


func _ready() -> void:
	custom_mat = default_material.duplicate()
	var path: String = ProjectSettings.globalize_path(default_material.resource_path)
	custom_mat.set_meta("original_path", path)
	default_material.set_meta("original_path", path)


func set_original_material(meshes: Array) -> void:
	custom_mat_node.hide()
	Tools.clear_node(plain_colors)
	plain_colors.get_parent().get_parent().hide()
	var mat_list: Array = []

	var mat_modified: bool = false
	for e in meshes:
		var mesh: MeshInstance = e as MeshInstance
		for iSurf in range(mesh.get_surface_material_count()):
			if mesh.get_surface_material(iSurf):
				mat_modified = true
				mesh.set_surface_material(iSurf, null)
			var mat: Material = mesh.mesh.surface_get_material(iSurf)
			if !mat_list.has(mat):
				mat_list.append(mat)
		if mesh.material_override:
			mat_modified = true
			mesh.material_override = null
	nmaterials = mat_list.size()

	if mat_modified:
		emit_signal("material_changed")


func set_custom_material(meshes: Array) -> void:
	Tools.clear_node(plain_colors)
	plain_colors.get_parent().get_parent().hide()
	Tools.clear_node(custom_mat_node.get_node("Scroll/Box"))

	custom_mat_node.show()
	if custom_mat_node.per_surface():
		Tools.clear_node(custom_mat_node.get_node("Scroll/Box"))
		var mat_names: Array = fill_materials(meshes, default_material, custom_mat_node.mat_dict)
		for mat_name in mat_names:
			var mat: Material = custom_mat_node.mat_dict[mat_name]
			if mat is SpatialMaterial:
				var item: Control = material_params_scn.instance()
				custom_mat_node.get_node("Scroll/Box").add_child(item)
				item.config_material(mat_name, mat, custom_mat_node, mat.get_meta("original_path"))
				assert(item.connect("material_changed", self, "_on_custom_material_changed") == OK)
				assert(item.connect("material_param_changed", self, "_on_custom_material_param_changed") == OK)
		nmaterials = mat_names.size()
	else:
		for meshInst in meshes:
			(meshInst as MeshInstance).material_override = custom_mat
		if custom_mat is SpatialMaterial:
			var item: Control = material_params_scn.instance()
			custom_mat_node.get_node("Scroll/Box").add_child(item)
			var mat_name: String = custom_mat.get_meta("original_path").get_file().get_basename()
			item.config_material(mat_name, custom_mat, custom_mat_node)
			item.show_path = false
			assert(item.connect("material_changed", self, "_on_custom_material_changed") == OK)
			assert(item.connect("material_param_changed", self, "_on_custom_material_param_changed") == OK)
		nmaterials = 1
	custom_mat_node.meshes = meshes

	emit_signal("material_changed")


func set_plain_colors(meshes: Array) -> void:
	custom_mat_node.hide()

	plain_colors.get_parent().get_parent().show()
	Tools.clear_node(plain_colors)
	var mat_names: Array = fill_materials(meshes, plain_material, plain_mat_dict)
	for mat_name in mat_names:
		var item: Control = plain_item_scn.instance()
		item.config_color(plain_mat_dict[mat_name].albedo_color, mat_name, self)
		plain_colors.add_child(item)
	nmaterials = mat_names.size()

	emit_signal("material_changed")


func fill_materials(meshes: Array, def_material: Material, dict: Dictionary) -> Array:
	var mat_names: Array = []
	var new_mats: Dictionary = {}
	for meshInst in meshes:
		(meshInst as MeshInstance).material_override = null
		var mesh: ArrayMesh = (meshInst as MeshInstance).mesh
		for iSurf in range(mesh.get_surface_count()):
			var surf_name: String = mesh.surface_get_name(iSurf)
			if not mat_names.has(surf_name):
				mat_names.append(surf_name)
			var mat: Material
			if dict.has(surf_name):
				mat = dict[surf_name]
			else:
				mat = def_material.duplicate()
				if def_material.has_meta("original_path"):
					mat.set_meta("original_path", def_material.get_meta("original_path"))
				dict[surf_name] = mat
				new_mats[surf_name] = mat
			meshInst.set_surface_material(iSurf, mat)
	var nmat: int = mat_names.size()
	var imat: int = 0
	for mat_name in mat_names:
		if new_mats.has(mat_name):
			var mat: Material = new_mats[mat_name]
			if mat is SpatialMaterial:
				var color: Color = Color.from_hsv(imat / float(nmat), 0.50, 0.75)
				mat.albedo_color = color
		imat += 1
	return mat_names


func clear() -> void:
	custom_mat_node.mat_dict = {}
	custom_mat_node.hide()
	Tools.clear_node(custom_mat_node.get_node("Scroll/Box"))
	custom_mat_node.meshes = []
	custom_mat = default_material.duplicate()
	custom_mat.resource_name = "default"

	plain_mat_dict = {}
	Tools.clear_node(plain_colors)
	plain_colors.get_parent().get_parent().hide()


func _on_plain_color_changed(color: Color, color_name: String) -> void:
	plain_mat_dict[color_name].albedo_color = color

	emit_signal("material_param_changed")


func _on_custom_material_path_changed(material_name: String, new_material: Material) -> void:
	if material_name == "":
		custom_mat = new_material.duplicate()
		custom_mat.set_meta("original_path", ProjectSettings.globalize_path(new_material.resource_path))
		set_custom_material(custom_mat_node.meshes)


func _on_custom_material_changed(_v1, _v2) -> void:
	emit_signal("material_changed")


func _on_custom_material_param_changed() -> void:
	emit_signal("material_param_changed")


func _on_PerSurface_toggled(_pressed: bool) -> void:
	set_custom_material(custom_mat_node.meshes)
