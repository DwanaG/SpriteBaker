tool
extends SplitContainer

export(NodePath) var pixel_density_path: NodePath


func _on_SpriteView_pixel_density_changed(value: float) -> void:
	get_node(pixel_density_path).value = value
