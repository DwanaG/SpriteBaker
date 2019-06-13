tool
extends Control


export(NodePath) var file_names_path: NodePath
export(NodePath) var file_extensions_path: NodePath
export(NodePath) var file_directories_path: NodePath
export(NodePath) var load_models_path: NodePath
export(NodePath) var load_all_path: NodePath

onready var file_names: ItemList = get_node(file_names_path) as ItemList
onready var file_exts: ItemList = get_node(file_extensions_path) as ItemList
onready var file_dirs: ItemList = get_node(file_directories_path) as ItemList


func select_item(index: int, selected: bool) -> void:
	if selected:
		file_names.select(index, false)
		file_exts.select(index, false)
		file_dirs.select(index, false)
		if !Input.is_key_pressed(KEY_CONTROL) && !Input.is_key_pressed(KEY_SHIFT):
			unselect_items(index)
	else:
		file_names.unselect(index)
		file_exts.unselect(index)
		file_dirs.unselect(index)

	get_node(load_models_path).disabled = !file_names.is_anything_selected()


func unselect_items(exception: int) -> void:
	for idx in range(file_names.get_item_count()):
		if idx != exception:
			file_names.unselect(idx)
			file_exts.unselect(idx)
			file_dirs.unselect(idx)


func get_files(only_selected: bool) -> PoolStringArray:
	var files: = PoolStringArray()
	var indices: PoolIntArray
	if only_selected:
		indices = file_names.get_selected_items()
	else:
		indices = PoolIntArray()
		var item_num: int = file_names.get_item_count()
		indices.resize(item_num)
		for i in range(item_num):
			indices[i] = i
	for idx in indices:
		var file_name: String = file_names.get_item_text(idx)
		var ext: String = file_exts.get_item_text(idx)
		var dir_path: String = file_dirs.get_item_text(idx)
		file_name = dir_path + "/" + file_name + "." + ext
		files.append(file_name)
	return files


func _on_FolderPath_files_updated(files: PoolStringArray) -> void:
	file_names.clear()
	file_exts.clear()
	file_dirs.clear()
	if files.size() == 0:
		file_names.add_item("(No files found)", null, false)
		file_exts.add_item("", null, false)
		file_dirs.add_item("", null, false)
		get_node(load_all_path).disabled = true
	else:
		for file_path in files:
			var file: String = file_path.get_file().get_basename()
			var ext: String = file_path.get_extension()
			var dir: String = file_path.get_base_dir()
			file_names.add_item(file)
			file_exts.add_item(ext)
			file_dirs.add_item(dir)
		get_node(load_all_path).disabled = false


func _on_FileNames_multi_selected(index: int, selected: bool) -> void:
	file_names.release_focus()
	select_item(index, selected)


func _on_FileExtensions_multi_selected(index: int, selected: bool) -> void:
	file_exts.release_focus()
	select_item(index, selected)


func _on_FileDirectories_multi_selected(index: int, selected: bool) -> void:
	file_dirs.release_focus()
	select_item(index, selected)
