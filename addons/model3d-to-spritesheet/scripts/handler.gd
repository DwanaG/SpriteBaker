tool
extends HBoxContainer

export(float) var min_height: float = 20
export(float) var max_height: float = 200
export(NodePath) var tree_path: NodePath

onready var tree: Tree = get_node(tree_path)

var moving: bool = false
var collapsed: bool = false
var height: float

func _ready() -> void:
	height = (min_height + max_height) / 2.0
	tree.rect_min_size.y = height


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if event.pressed:
			moving = true
		else:
			moving = false
	elif event is InputEventMouseMotion && moving:
		var rel: float = event.relative.y
		height = tree.rect_min_size.y + rel
		height = max(min(height, max_height), min_height)
		if height == min_height:
			collapse()
		elif collapsed:
			expand()
		else:
			tree.rect_min_size.y = height


func collapse() -> void:
	$Collapse.texture = preload("res://addons/model3d-to-spritesheet/icons/arrow_down.svg")
	tree.rect_min_size.y = min_height
	collapsed = true
	tree.get_root().collapsed = true


func expand() -> void:
	$Collapse.texture = preload("res://addons/model3d-to-spritesheet/icons/arrow_up.svg")
	if height == min_height:
		height = (min_height + max_height) / 2.0
	tree.rect_min_size.y = height
	collapsed = false
	tree.get_root().collapsed = false


func _on_Collapse_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.pressed:
		if collapsed:
			expand()
		else:
			collapse()


func _on_AnimationsTree_visibility_changed() -> void:
	if tree.is_visible_in_tree():
		show()
	else:
		hide()


func _on_AnimationsTree_item_collapsed(item: TreeItem) -> void:
	if item == tree.get_root():
		if item.collapsed:
			collapse()
		else:
			expand()
