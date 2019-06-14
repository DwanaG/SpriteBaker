tool
extends EditorPlugin

"""
	Plugin to convert a 3D model into pixel-art sprites.
	When enabled, the plugin can be found under Project > Tools > 3D to Sprite sheet

	MATERIALS
	---------

	The plugin offers 3 different options for material setup:
		- Use original materials.
		- Use custom material. With this option there is the possibility to choose
			any Godot material file (in *.material, *.tres or *.res format). The
			materials must be of type SpatialMaterial or ShaderMaterial with
			shader_type set to spatial [ShaderMaterial not properly supported for the
			moment]. It also has the option to apply materials per surface. Different
			material parameters can be configured within the plugin, such as
			albedo_color, albedo_texture, roughness, metallic...
		- Plain colors. This option applies an unshaded material to the model with
			a different configurable color for each surface.

	Materials can be shared across different MeshInstances in the same model and across
	different models for mesh surfaces with the same name.

	IMPORTANT NODES
	---------------

	The functionality of the tool has been distributed among different nodes in
	the MainUI scene to make it more modular. Some important nodes are shown
	below:

	FolderPath [folder_path.gd] - Contains the current folder where 3D models are
			going to be searched. The search is done also on subdirectories one level
			deep. When selecting a new path, a signal is emitted (files_updated)
			with a list of found files.
	FilesContainer [file_spreadsheet.gd] - Catches the signal from FolderPath and
			populates a spreadsheet with the found files.
	Loader [loader.gd] - Models are loaded by this node. It also makes sure that the
			selected model in ModelsOption is displayed in the 3D View.
	3D View [viewport_3d.gd] - Shows the selected model from ModelsOption's list.
	Sprite [sprite.gd] - Shows a preview of the model as an image.
	GenScene [gen_scene.gd] - Scene to properly dislpay the model
	SpriteGenerator [sprite_generator.gd] - Converts the 3D scene into sprites
"""

var dialog: AcceptDialog

func _enter_tree() -> void:
	add_tool_menu_item("Sprite Baker", self, "_on_tool_menu_pressed")
	get_dialog()


func _exit_tree() -> void:
	remove_tool_menu_item("Sprite Baker")
	if dialog:
		remove_control_from_container(CONTAINER_TOOLBAR, dialog)
		dialog.free()


func get_dialog() -> void:
	dialog = load("res://addons/sprite-baker/scenes/ConverterDialog.tscn").instance()
	add_control_to_container(CONTAINER_TOOLBAR, dialog)


func _on_tool_menu_pressed(_ud) -> void:
	if !is_inside_tree():
		return
	if not dialog:
		get_dialog()
	dialog.popup_centered_ratio(0.85)
