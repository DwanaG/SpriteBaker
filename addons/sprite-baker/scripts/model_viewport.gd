tool
extends ViewportContainer


const LOOKAROUND_SPEED: float = 0.01

#export(NodePath) var material_options_path: NodePath
#export(NodePath) var info_path: NodePath
#
#onready var material_options: OptionButton = get_node(material_options_path)
#onready var info: Label = get_node(info_path)

var rotate: bool = false
var rotx: float = 0.0
var roty: float = 0.0

var process_gui: bool = false
var mouse_pos: Vector2
var rot_factor: float = 1.0

#var info_txt: String = ""


func _gui_input(event: InputEvent) -> void:
	if !process_gui:
		return
	if event is InputEventMouseButton && \
		(event.button_index == BUTTON_MIDDLE || event.button_index == BUTTON_RIGHT):
		if event.is_pressed():
			rotate = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_pos = event.position
		else:
			rotate = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			warp_mouse(mouse_pos)
	elif rotate && event is InputEventMouseMotion:
		rotx += event.relative.x * LOOKAROUND_SPEED * rot_factor
		roty += event.relative.y * LOOKAROUND_SPEED * rot_factor
		for node in get_tree().get_nodes_in_group("3D2SS.ModelViewport"):
			node.rotate_model(rotx, roty)


func _get_resolution() -> Vector2:
	return self.rect_size


func update_model(model: Spatial) -> void:
	$Viewport3D/Scene3D.set_model(model.duplicate())
	rotx = 0.0
	roty = 0.0
	process_gui = true


func clear_model() -> void:
	$Viewport3D/Scene3D.set_model(null)
	process_gui = false


func rotate_model(rx: float, ry: float) -> void:
	rotx = wrapf(rx, -PI, PI)
	roty = wrapf(ry, -PI, PI)
	$Viewport3D/Scene3D.rotate_model(rotx, roty)


#	info_txt = ""
#	if (get_parent() as TabContainer).current_tab == 0:
#		info.text = ""
#
#
#func show_info() -> void:
#	pass
#	if info_txt == "":
#		var meshes: Array = $Viewport3D/GenScene.meshes
#		var num_tris: int = 0
#		for meshInst in meshes:
#			var faces: PoolVector3Array = (meshInst as MeshInstance).mesh.get_faces()
#			num_tris += int(faces.size() / 3.0)
#
#		info_txt = "Tris: " + Tools.format_int_with_commas(num_tris)
#		info_txt += " | Materials: " + String(material_options.nmaterials)
#	if (get_parent() as TabContainer).current_tab == 0:
#		info.text = info_txt
#
#
#func check_material_type(mat_type: int) -> void:
#	var model: Spatial = $Viewport3D/GenScene.model
#	if model == null:
#		return
#	if not model.has_meta("MaterialType"):
#		model.set_meta("MaterialType", MatType.NONE)
#	if model.get_meta("MaterialType") != mat_type:
#		set_materials(mat_type)
#		model.set_meta("MaterialType", mat_type)
#
#
#func update_material_info() -> void:
#	if info_txt != "":
#		var parts: PoolStringArray = info_txt.split("|")
#		parts[1] = " Materials: " + String(material_options.nmaterials)
#		info_txt = parts[0] + "|" + parts[1]
#	show_info()
#
#
#func _on_MaterialOptions_item_selected(id: int) -> void:
#	check_material_type(id)
#	update_material_info()
#
#
#func _on_TabContainer_tab_changed(_tab: int):
#	show_info()
#
#
#func _on_PerSurface_toggled(_button_pressed: bool) -> void:
#	yield(get_tree(), "idle_frame")
#	update_material_info()
