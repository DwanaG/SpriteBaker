tool
extends VBoxContainer

const Tools: Script = preload("tools.gd")

export(PackedScene) var material_param_scn: PackedScene
export(SpatialMaterial) var default_material: SpatialMaterial
export(NodePath) var materials_list_path: NodePath

onready var materials_list: BoxContainer = get_node(materials_list_path)


func update_model(model: Spatial) -> void:
	yield(get_tree(), "idle_frame")
	Tools.clear_node(materials_list)
	var list: Array = []
	var mat_dict: Dictionary = {}
	var meshes: Array = Tools.find_nodes_by_type("MeshInstance", model)
	for mi in meshes:
		var mesh: ArrayMesh = (mi as MeshInstance).mesh
		for isurf in range(mesh.get_surface_count()):
			var surf_name: String = mesh.surface_get_name(isurf)
			if !mat_dict.has(surf_name):
				var mat: Material = mesh.surface_get_material(isurf)
				if not mat is SpatialMaterial:
					mat = default_material
				var mat_props: Control = material_param_scn.instance()
				mat_props.init(surf_name, mat.resource_path, mat.duplicate())
				mat_props.name = surf_name
				mat_dict[surf_name] = mat_props
				list.append(surf_name)
	list.sort()
	var nmat: int = list.size()
	var imat: int = 0
	for surf_name in list:
		var mat_props: Control = mat_dict[surf_name]
		materials_list.add_child(mat_props)
		var color: Color = Color.from_hsv(imat / float(nmat), 0.50, 0.75)
		mat_props.set_plain_color(color)
		imat += 1


func clear_model() -> void:
	Tools.clear_node(materials_list)

