tool
extends MarginContainer

signal frame_moved(moved_index, receiver_index, to_left)
signal minimized(frame)
signal maximized(frame)

const TITLE_SCROLL_SENSITIVITY: int = 5

export(String) var title: String = "(Frame title)" setget set_title, get_title
export(String, FILE, "*.tscn; TSCN, *.scn; SCN, *.res; RES") var preview_scn_path: String
export(NodePath) var title_path: NodePath
export(NodePath) var title_box_path: NodePath
export(NodePath) var min_title_path: NodePath
export(NodePath) var min_button_path: NodePath
export(NodePath) var move_left_path: NodePath
export(NodePath) var move_right_path: NodePath

onready var preview_scn: PackedScene = load(preview_scn_path)
onready var title_box: Container = get_node(title_box_path)

var dragging: bool = false
var minimized: bool = false
var title_shifted: bool = false
var minimized_width: int
var maximized_width: int


func _ready() -> void:
	set_process_input(false)
	minimized_width = $MinBar.rect_min_size.x + \
		get_constant("margin_left") + get_constant("margin_right")
	check_ends()



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.is_pressed():
		if dragging:
			if minimized:
				$MinBar.show()
			else:
				$Box.show()
			yield(get_tree(), "idle_frame")
			dragging = false
		else:
			hide_highlight()
		set_process_input(false)
	elif event is InputEventMouseMotion:
		if !(dragging || get_rect().has_point(event.position)):
			hide_highlight()
			set_process_input(false)


func set_title(new_title: String) -> void:
	title = new_title
	get_node(title_path).text = title
	get_node(min_title_path).text = title

func get_title() -> String:
	return title


func get_drag_data(position: Vector2) -> Object:
	if minimized or $Box/TitleBar.get_rect().has_point(position):
		dragging = true
		var preview: Control = preview_scn.instance()
		preview.rect_min_size = Vector2(100, 100)
		preview.rect_size = Vector2(100, 100)
		set_drag_preview(preview)
		preview.set_title(title)
		set_process_input(true)
		if minimized:
			$MinBar.hide()
		else:
			$Box.hide()
		return self
	return null


func can_drop_data(position: Vector2, dropped) -> bool:
	if dropped.get_script() == self.get_script() and dropped.dragging:
		if self != dropped:
			if position.x > self.rect_size.x * 0.5:
				$DropRight.show()
				$DropLeft.hide()
			else:
				$DropRight.hide()
				$DropLeft.show()
			set_process_input(true)
		return true
	else:
		return false


func drop_data(position: Vector2, dropped) -> void:
	if dropped == self:
		return
	hide_highlight()
	emit_signal("frame_moved", dropped.get_position_in_parent(),
								get_position_in_parent(),
								position.x < self.rect_size.x * 0.5)


func minimize() -> void:
	minimized = true
	maximized_width = int(max(self.rect_size.x, 2 * minimized_width))
	$Box.hide()
	$MinBar.show()
	if title_shifted:
		title_box.rect_position.x = 0
		title_box.margin_right = 0
		title_shifted = false


func maximize() -> void:
	minimized = false
	$Box.show()
	$MinBar.hide()


func hide_highlight() -> void:
	$DropLeft.hide()
	$DropRight.hide()


func disable_minimize() -> void:
	get_node(min_button_path).disabled = true


func enable_minimize() -> void:
	get_node(min_button_path).disabled = false


func fix_title_box(increase: int) -> void:
	if title_box.get_combined_minimum_size().x < title_box.get_parent().rect_size.x:
		title_box.rect_position.x = 0
		title_box.margin_right = 0
		title_shifted = false
	else:
		title_box.margin_right -= increase
		if title_box.margin_right < 0:
			title_box.rect_position.x -= title_box.margin_right
			title_box.margin_right = 0


func check_ends() -> void:
	var index: int = get_position_in_parent()
	get_node(move_left_path).disabled = true if index == 0 else false
	get_node(move_right_path).disabled = true if index == get_parent().get_child_count() - 1 else false


func _on_Minimize_pressed() -> void:
	minimized = true
	emit_signal("minimized", self)


func _on_Maximize_pressed() -> void:
	emit_signal("maximized", self)


func _on_TitleBox_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if title_box.rect_size.x > title_box.get_parent().rect_size.x:
			if event.button_index == BUTTON_WHEEL_UP:
				title_box.rect_position.x += TITLE_SCROLL_SENSITIVITY
				if title_box.margin_left > 0:
					title_box.rect_position.x -= title_box.margin_left
				title_shifted = true
			elif event.button_index == BUTTON_WHEEL_DOWN:
				title_box.rect_position.x -= TITLE_SCROLL_SENSITIVITY
				if title_box.margin_right < 0:
					title_box.rect_position.x -= title_box.margin_right
				if title_box.margin_right == 0:
					title_shifted = false


func _on_MoveLeft_pressed() -> void:
	var index: int = get_position_in_parent()
	emit_signal("frame_moved", index, index - 2, true)


func _on_MoveRight_pressed() -> void:
	var index: int = get_position_in_parent()
	emit_signal("frame_moved", index, index + 2, false)



