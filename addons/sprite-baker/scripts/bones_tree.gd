tool
extends Tree

signal root_motion_selected(node_path, id)

const Tools: Script = preload("tools.gd")
const SpatialIcon: Texture = preload("res://addons/sprite-baker/icons/spatial.svg")
const SkeletonIcon: Texture = preload("res://addons/sprite-baker/icons/skeleton.svg")
const BoneIcon: Texture = preload("res://addons/sprite-baker/icons/bone.svg")
const NodeIcon: Texture = preload("res://addons/sprite-baker/icons/node.svg")

export(NodePath) var root_motion_button_path: NodePath

onready var root_motion: Button = get_node(root_motion_button_path)


func update_model(model: Spatial) -> void:
	clear()
	var skeleton: Skeleton = Tools.find_single_node_by_type("Skeleton", model)
	if not skeleton:
		root_motion.disabled = true
		return
	root_motion.disabled = false
	var parent: Node = model
	var hierarchy: Array = []
	while parent != skeleton:
		for child in parent.get_children():
			if child.is_a_parent_of(skeleton) || child == skeleton:
				hierarchy.append(child)
				parent = child
				break
	var item: TreeItem = null
	var path: String = ""
	for node in hierarchy:
		item = create_item(item)
		var icon: Texture = null
		if node is Skeleton:
			icon = SkeletonIcon
		elif node is Spatial:
			icon = SpatialIcon
		else:
			icon = NodeIcon
		if path != "":
			path += "/"
		path += node.name
		item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
		item.set_icon(0, icon)
		item.set_text(0, node.name)
		if node is Spatial:
			item.set_metadata(0, [path, -1])
		else:
			item.set_selectable(0, false)
	var bone_items: Dictionary = {}
	bone_items[-1] = item
	for ibone in skeleton.get_bone_count():
		add_bone(bone_items, skeleton, ibone, path)


func clear_model() -> void:
	clear()
	root_motion.disabled = true


func add_bone(dict: Dictionary, skeleton: Skeleton, ibone: int, path: String) -> void:
	if dict.has(ibone):
		return
	var parent_id: int = skeleton.get_bone_parent(ibone)
	if not dict.has(parent_id):
		add_bone(dict, skeleton, parent_id, path)
	var parent: TreeItem = dict[parent_id]
	var item: TreeItem = create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
	item.set_icon(0, BoneIcon)
	item.set_text(0, skeleton.get_bone_name(ibone))
	item.set_metadata(0, [path, ibone])
	dict[ibone] = item


func select() -> void:
	var selected: TreeItem = get_selected()
	if selected:
		root_motion.text = selected.get_text(0)
		root_motion.icon = selected.get_icon(0)
		var data: Array = selected.get_metadata(0)
		emit_signal("root_motion_selected", data[0], data[1])


func _on_RootMotionDialog_confirmed() -> void:
	select()


func _on_item_activated() -> void:
	select()
	get_parent().get_parent().hide()
