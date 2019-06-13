tool
extends HBoxContainer

const Tools: Script = preload("tools.gd")

enum Side {LEFT = -1, RIGHT = 1}

var expanded_frame: int = 0
var frames_distribution: Dictionary
var dragger_active: bool = false
var frames: Array = []


func _ready() -> void:
	for child in get_children():
		if child is Container:
			frames.append(child)
	update_frames_distribution()
	if not Tools.is_node_being_edited(self):
		for node in get_tree().get_nodes_in_group("3D2SS:FileDialog"):
			node.current_dir = Tools.get_addon_path(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var covered: int = 0
		for child in get_children():
			if child is Separator:
				covered += child.rect_size.x
		covered += (get_child_count() - 1) * get_constant("separation")
		var remaining: int = int(rect_size.x - covered)
		resize_frames(remaining)


func resize_frames(total_coverage: int) -> void:
	var coverage: int = total_coverage
	var effective: float = 0.0
	var update_dict: Dictionary = {}
	var has_minimized: bool = false
	for frame in frames:
		var index: int = frame.get_position_in_parent()
		if frame.minimized:
			coverage -= frame.minimized_width
			frames_distribution[index] = frame.minimized_width /float(total_coverage)
			has_minimized = true
		else:
			effective += frames_distribution[index]
			update_dict[index] = frame
	if has_minimized:
		for index in update_dict:
			frames_distribution[index] = coverage * frames_distribution[index] / (effective * total_coverage)
	for frame in frames:
		var index: int = frame.get_position_in_parent()
		var min_x: int = int(frames_distribution[index] * total_coverage)
		if frame.title_shifted and min_x > frame.rect_size.x:
			frame.fix_title_box(min_x - frame.rect_size.x)
		if index != expanded_frame:
			frame.rect_min_size.x = min_x


func update_frames_distribution() -> void:
	frames_distribution = {}
	var frames_coverage: int = get_frames_coverage()
	for frame in frames:
		var index: int = frame.get_position_in_parent()
		frames_distribution[index] = frame.rect_size.x / float(frames_coverage)


func get_frames_coverage() -> int:
	var frames_coverage: int = 0
	for frame in frames:
		frames_coverage += frame.rect_size.x
	return frames_coverage


func find_frame(index: int, dir: int) -> Control:
	var frame: Control = null
	var ctrl_index: int = index + dir
	while ctrl_index >= 0 && ctrl_index <= get_child_count() - 1:
		frame = get_child(ctrl_index)
		if not frame.minimized:
			break
		ctrl_index += 2 * dir
		frame = null
	return frame


func set_expanded_frame(frame: Container) -> void:
	var exp_frame: Container = get_child(expanded_frame)
	exp_frame.size_flags_horizontal = SIZE_FILL
	exp_frame.rect_min_size.x = int(frames_distribution[expanded_frame] * get_frames_coverage())
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	frame.rect_min_size.x = 0.0
	expanded_frame = frame.get_position_in_parent()


func minimize_frame(frame: Container, next_frame: Container) -> void:
	frame.minimize()
	if frame.get_position_in_parent() == expanded_frame:
		if next_frame == null:
			for frame in frames:
				if not frame.minimized:
					next_frame = frame
					break
		set_expanded_frame(next_frame)
	var max_count: int = 0
	for frame in frames:
		if not frame.minimized:
			max_count += 1
			if max_count > 1:
				break
	if max_count == 1:
		get_child(expanded_frame).disable_minimize()


func maximize_frame(frame: Container) -> void:
	get_child(expanded_frame).enable_minimize()
	frame.maximize()


func _on_frame_moved(moved_index: int, receiver_index: int, to_left: bool) -> void:
	var expanded_ctrl: Control = get_child(expanded_frame)
	var moved_child: Control = get_child(moved_index)
	var recieiver_child: Control = get_child(receiver_index)
	if to_left:
		var separator: Separator
		if moved_index == get_child_count() - 1:
			separator = get_child(moved_index - 1)
		else:
			separator = get_child(moved_index + 1)
		if moved_index < receiver_index:
			var index = receiver_index - 1
#			moved_child = get_child(moved_index)
			move_child(moved_child, index)
			move_child(separator, index)
		else:
#			moved_child = get_child(moved_index)
			move_child(separator, receiver_index)
			move_child(moved_child, receiver_index)
	else:
		var separator: Separator
		if moved_index == 0:
			separator = get_child(moved_index + 1)
		else:
			separator = get_child(moved_index - 1)
		if receiver_index < moved_index:
#			var moved: Control = get_child(moved_index)
			move_child(separator, receiver_index + 1)
			move_child(moved_child, receiver_index + 2)
		else:
			move_child(moved_child, receiver_index)
			move_child(separator, receiver_index - 1)
	expanded_frame = expanded_ctrl.get_position_in_parent()
	update_frames_distribution()
	moved_child.check_ends()
	recieiver_child.check_ends()


func _on_dragger_gui_input(event: InputEvent, node: String) -> void:
	var index: int = get_node(node).get_position_in_parent()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		dragger_active = event.is_pressed()
	elif dragger_active and event is InputEventMouseMotion:
		var relative: float = event.relative.x
		var left_frame: Control = null
		var right_frame: Control = null
		if relative > 0.0:
			left_frame = get_child(index - 1)
			right_frame = find_frame(index, Side.RIGHT)
		else:
			left_frame = find_frame(index, Side.LEFT)
			right_frame = get_child(index + 1)
		if not (left_frame && right_frame):
			return
		var left_width: int = left_frame.rect_size.x + event.relative.x
		var right_width: int = right_frame.rect_size.x - event.relative.x
		var left_index: int = left_frame.get_position_in_parent()
		var right_index: int = right_frame.get_position_in_parent()
		if left_frame.minimized:
			maximize_frame(left_frame)
		elif left_width <= left_frame.minimized_width:
			var d: int = int(left_frame.minimized_width) - left_width
			left_width += d
			right_width -= d
			minimize_frame(left_frame, right_frame)
		if right_frame.minimized:
			maximize_frame(right_frame)
		elif right_width <= right_frame.minimized_width:
			var d: int = int(right_frame.minimized_width) - right_width
			left_width -= d
			right_width += d
			minimize_frame(right_frame, left_frame)
		if left_frame.title_shifted and left_width > left_frame.rect_size.x:
			left_frame.fix_title_box(left_width - left_frame.rect_size.x)
		if expanded_frame != left_index:
			left_frame.rect_min_size.x = left_width
		if right_frame.title_shifted and right_width > right_frame.rect_size.x:
			right_frame.fix_title_box(right_width - right_frame.rect_size.x)
		if expanded_frame != right_index:
			right_frame.rect_min_size.x = right_width
		var frames_coverage: float = get_frames_coverage()
		frames_distribution[left_index] = left_width / frames_coverage
		frames_distribution[right_index] = right_width / frames_coverage


func _on_frame_minimized(frame: Container) -> void:
	resize_frames(get_frames_coverage())
	minimize_frame(frame, null)


func _on_frame_maximized(frame: Container) -> void:
	var coverage: int = get_frames_coverage()
	var f: float = min(frame.maximized_width / float(coverage), 0.6)
	var index: int = frame.get_position_in_parent()
	var diff: float = f - frames_distribution[index]
	frames_distribution[index] = f
	var list: Array = []
	for frame in frames:
		if not frame.minimized:
			list.append(frame)
	diff /= float(list.size())
	for fr in list:
		var i: int = fr.get_position_in_parent()
		frames_distribution[i] = frames_distribution[i] - diff
	maximize_frame(frame)
	resize_frames(coverage)

