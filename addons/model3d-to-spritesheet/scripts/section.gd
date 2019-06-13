tool
extends Button

export(int) var elements: int = 0


func _toggled(button_pressed: bool) -> void:
	var index: int = get_index() + 1
	var parent: Node = get_parent()
	if button_pressed:
		self.icon = preload("res://addons/model3d-to-spritesheet/icons/arrow_down.svg")
	else:
		self.icon = preload("res://addons/model3d-to-spritesheet/icons/arrow_right.svg")
	for i in range(elements):
		if button_pressed:
			parent.get_child(index + i).show()
		else:
			parent.get_child(index + i).hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		var index: int = get_index() + 1
		var parent: Node = get_parent()
		if is_visible_in_tree():
			for i in range(elements):
				parent.get_child(index + i).show()
		else:
			for i in range(elements):
				parent.get_child(index + i).hide()