tool
extends VBoxContainer

const Tools: Script = preload("tools.gd")

export(NodePath) var folder_node_path: NodePath
export(NodePath) var file_tree_path: NodePath
export(NodePath) var file_list_path: NodePath
export(NodePath) var load_all_path: NodePath
export(NodePath) var load_path: NodePath
export(NodePath) var clear_path: NodePath

onready var folder: LineEdit = get_node(folder_node_path)
onready var file_list: ItemList = get_node(file_list_path)

var original_path: String


func _ready() -> void:
	if !Tools.is_node_being_edited(self):
		folder.folder_path = Tools.get_addon_path(self) + "models/"

	## DEBUG
	if not Engine.is_editor_hint():
		_on_LoadAll_pressed()


func load_models(all: bool) -> void:
	var files: PoolStringArray = get_node(file_tree_path).get_files(all)
	$Loader.load_models(files)


func _on_SearchFolder_pressed() -> void:
	var dialog: FileDialog
	for node in get_tree().get_nodes_in_group("3D2SS.FileDialog"):
		if node is FileDialog:
			dialog = node
			break
	original_path = dialog.current_dir
	dialog.current_dir = folder.folder_path
	dialog.mode = FileDialog.MODE_OPEN_DIR
	dialog.popup_centered(Vector2(500, 500))
	if !dialog.is_connected("dir_selected", self, "_on_dir_selected"):
		assert(dialog.connect("dir_selected", self, "_on_dir_selected", [dialog]) == OK)


func _on_dir_selected(dir: String, dialog: FileDialog) -> void:
	folder.folder_path = dir
	dialog.disconnect("dir_selected", self, "_on_dir_selected")
	dialog.current_dir = original_path


func _on_FolderPath_files_updated(file_names: PoolStringArray, _base_dir: String) -> void:
	get_node(load_all_path).disabled = file_names.size() == 0


func _on_FileTree_selected_files(selected: bool) -> void:
	get_node(load_path).disabled = !selected


func _on_LoadAll_pressed() -> void:
	load_models(true)


func _on_Load_pressed() -> void:
	load_models(false)


func _on_Loader_loading_finished() -> void:
	file_list.clear()
	for imodel in range($Loader.files.size()):
		var item_name: String = $Loader.files[imodel].get_file()
		file_list.add_item(item_name)
		file_list.set_item_metadata(imodel, imodel)
	file_list.sort_items_by_text()
	get_node(clear_path).disabled = false

	## DEBUG
	if not Engine.is_editor_hint():
		_on_List_item_selected(0)


func _on_Clear_pressed() -> void:
	for node in get_tree().get_nodes_in_group("3D2SS.ModelData"):
		node.clear_model()
	get_node(clear_path).disabled = true
	file_list.clear()
	$Loader.clear()


func _on_List_item_selected(index: int) -> void:
	var id: int = file_list.get_item_metadata(index)
	$Loader.select(id)
