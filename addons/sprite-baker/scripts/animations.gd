tool
extends VBoxContainer

export(NodePath) var orientation_path: NodePath

var or_menu: PopupMenu


func _ready() -> void:
	or_menu = get_node(orientation_path).get_popup()
	or_menu.hide_on_checkable_item_selection = false
	or_menu.connect("index_pressed", self, "_on_or_menu_index_pressed")


func _on_or_menu_index_pressed(index: int) -> void:
	or_menu.toggle_item_checked(index)
