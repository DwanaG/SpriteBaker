tool
extends VBoxContainer

const MAT_EXTS: = PoolStringArray([
	"*.material; Material", "*.tres; Text Resource", "*.res; Resource"
	])
const TEXTURE_EXTS: = PoolStringArray([
	"*.bmp, BMP", "*.jpeg; JPEG", "*.jpg; JPG", "*.png; PNG", "*.res; RES",
	"*.tres; TRES", "*.tex; TEX", "*.tga; TGA", "*.webp; WEBP"
	])

var dialog_calling_subnode: String
var dialog_calling_node: Node

var meshes: Array
var mat_dict: Dictionary = {}


func per_surface() -> bool:
	return $CustomOptions/PerSurface.pressed


func _on_PerSurface_toggled(pressed: bool) -> void:
	$CustomOptions/Material.editable = !pressed
	$CustomOptions/LoadMaterial.disabled = pressed
	$CustomOptions/MaterialLabel.add_color_override("font_color", Color.gray if pressed else Color.white)


func _on_LoadMaterial_pressed():
	dialog_calling_subnode = "."
	$ResourceDialog.filters = MAT_EXTS
	$ResourceDialog.popup_centered(Vector2(500, 500))


func _on_ResourceDialog_file_selected(path: String):
	if dialog_calling_subnode == ".":
		$CustomOptions/Material.material_path = path
	else:
		dialog_calling_node.dialog_result_path(path, dialog_calling_subnode)
	dialog_calling_subnode = ""


func _on_dialog_requested(node: Node, subnode_path: String, res_type: String):
	dialog_calling_node = node
	dialog_calling_subnode = subnode_path
	$ResourceDialog.filters = TEXTURE_EXTS if res_type == "Texture" else MAT_EXTS
	$ResourceDialog.popup_centered(Vector2(500, 500))


func _on_material_changed(mat_name: String, new_material: Material) -> void:
	mat_dict[mat_name] = new_material
	for meshInst in meshes:
		var mesh: ArrayMesh = (meshInst as MeshInstance).mesh
		for iSurf in range(mesh.get_surface_count()):
			if mat_name == mesh.surface_get_name(iSurf):
				meshInst.set_surface_material(iSurf, new_material)
