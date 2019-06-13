tool
extends HBoxContainer

func config_color(color: Color, name: String, node: Node) -> void:
	$Color.color = color
	$Name.text = name
	assert($Color.connect("color_changed", node, "_on_plain_color_changed", [name]) == OK)
	self.name = name
