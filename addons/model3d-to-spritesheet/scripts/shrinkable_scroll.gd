tool
extends ScrollContainer

export(int) var max_height: int = 100


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var height: int = get_child(0).rect_size.y
		self.rect_min_size.y = height if height < max_height else max_height