tool
extends TextureRect


func set_texture(new_texture: Texture) -> void:
	texture = new_texture
	if texture:
		$Size.show()
	else:
		$Size.hide()


func _on_Size_toggled(button_pressed: bool):
	if button_pressed:
		$Size.icon = preload("res://addons/model3d-to-spritesheet/icons/expand.svg")
		$Size.hint_tooltip = "Expand"
		self.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	else:
		$Size.icon = preload("res://addons/model3d-to-spritesheet/icons/shrink.svg")
		$Size.hint_tooltip = "Shrink"
		self.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
