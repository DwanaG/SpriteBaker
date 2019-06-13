tool
extends Control

"""
	GUI parent node for the 3D model to sprite sheet tool.
	This script only initializes the default directory path and shows the search
	folder dialog when needed. Other functionalities are spread across different
	nodes in the MainUI scene.
"""

const Tools: Script = preload("tools.gd")

export(NodePath) var folder_path: NodePath
export(NodePath) var file_dialog_path: NodePath
export(NodePath) var resource_dialog_path: NodePath

func _ready() -> void:
	"""
		Initializes the path for nodes that need it. The default path points
		to this plugin location
	"""
	if !Tools.is_node_being_edited(self):
		init_path()


func init_path() -> void:
	var default_path: String  = get_addon_path()
	var models_path: String = default_path + "models/"
	get_node(folder_path).folder_path = models_path
	get_node(file_dialog_path).current_path = models_path
	get_node(resource_dialog_path).current_path = default_path + "materials/"


func get_addon_path() -> String:
	"""
		Finds the path to the plugin by looking at the path of this script
	"""
	var script_path: String = get_script().resource_path
	var file: = File.new()
	assert(file.open(script_path, File.READ) == OK)
	var path: String = file.get_path_absolute()
	file.close()
	path = path.get_base_dir().trim_suffix("scripts")
	return path

func _on_SearchFolder_pressed():
	"""
		When the SearchFolder button is pressed, the FileDialog is shown
	"""
	get_node(file_dialog_path).popup_centered(Vector2(500, 500))

