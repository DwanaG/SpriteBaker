tool
extends "line_edit.gd"

signal material_path_changed(material_name, new_material)

var material_name: String = ""

var material_path: String = "" setget set_material_path, get_material_path


func _text_entered(new_path: String) -> void:
	self.material_path = new_path


func set_material_path(new_path: String) -> void:
	if material_path == new_path:
		return
	if new_path != "" && ResourceLoader.exists(new_path):
		var res: Resource = load(new_path)
		if res is SpatialMaterial || res is ShaderMaterial:
			material_path = new_path
			emit_signal("material_path_changed", material_name, res as Material)
	self.text = material_path

func get_material_path() -> String:
	return material_path