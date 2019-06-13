tool
extends "line_edit.gd"

signal files_updated(file_names, base_dir)

const SUPPORTED_EXTENSIONS = ["dae", "glb", "obj"]

var folder_path: String = "" setget set_folder_path, get_folder_path
var MARGIN: int


func _ready() -> void:
	var stbx: StyleBoxFlat = get_stylebox("normal")
	MARGIN = int(get_icon("clear").get_width() + stbx.content_margin_left + \
		stbx.content_margin_right)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		self.text = fit_text(folder_path)


func _text_entered(new_text: String) -> void:
	self.folder_path = new_text


func set_folder_path(new_path: String) -> void:
	if folder_path == new_path:
		return
	var dir: = Directory.new()
	if new_path != "" && dir.dir_exists(new_path):
		folder_path = new_path
		if !folder_path.ends_with("/"):
			folder_path += "/"
		var files: PoolStringArray = search_files(folder_path, true)
		emit_signal("files_updated", files, folder_path)
		hint_tooltip = folder_path
	self.text = fit_text(folder_path)


func get_folder_path() -> String:
	return folder_path


func search_files(dir_path: String, recursive: bool) -> PoolStringArray:
	var files: = PoolStringArray()
	var dir: = Directory.new()
	assert(dir.open(dir_path) == OK)
	assert(dir.list_dir_begin(true, true) == OK)
	var file_name: String = dir.get_next()
	while (file_name != ""):
		if dir.current_is_dir():
			if recursive:
				files.append_array(search_files(dir_path + file_name + "/", false))
		elif is_3d_model(file_name):
			files.append(dir_path + file_name)
		file_name = dir.get_next()
	return files


func is_3d_model(file_name: String) -> bool:
	var file_ext: String = file_name.get_extension()
	for ext in SUPPORTED_EXTENSIONS:
		if file_ext == ext:
			return true
	return false


func fit_text(in_text: String) -> String:
	if in_text == "":
		return ""
	var font: Font = get_font("font")
	var text_width: float = font.get_string_size(in_text).x
	var width: float = self.rect_size.x - MARGIN
	var length: int = in_text.length()
	if text_width > width:
		var nchars: int = int(ceil(width * length / text_width))
		var out_text: String = ".."
		for ichar in range(nchars, 0, -1):
			var txt: String = "%s..%s" % \
				[in_text.left(int(min(ichar,10))), in_text.right(length - ichar)]
			if font.get_string_size(txt).x <= width:
				if txt.length() >= length:
					txt = in_text
				out_text = txt
				break
		return out_text
	else:
		return in_text
