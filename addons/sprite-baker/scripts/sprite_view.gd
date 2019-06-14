tool
extends "model_viewport.gd"

signal pixel_density_changed(value)

const MAX_PIXELS: int = 3840

var res_x: int = 1
var res_y: int = 1

var pixel_dens: float = 32.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		self.rect_pivot_offset = self.rect_size * 0.5


func update_model(model: Spatial) -> void:
	.update_model(model)
	adjust_viewport()


func adjust_viewport() -> void:
	var aabb: AABB = $Viewport3D/Scene3D.aabb
	res_x = int(ceil(aabb.size.x * pixel_dens))
	res_y = int(ceil(aabb.size.y * pixel_dens))
	if res_x > MAX_PIXELS || res_y > MAX_PIXELS:
		if res_x > res_y:
			res_y = int(ceil(res_y * MAX_PIXELS / float(res_x)))
			res_x = MAX_PIXELS
		else:
			res_x = int(ceil(res_x * MAX_PIXELS / float(res_y)))
			res_y = MAX_PIXELS
		pixel_dens = int(res_x / aabb.size.x)
		emit_signal("pixel_density_changed", pixel_dens)
	fit_model()


func fit_model() -> void:
	var pratio: float = get_parent().rect_size.x / get_parent().rect_size.y
	var ratio: float = res_x / float(res_y)
	var scale: float
	if ratio > pratio:
		scale = get_parent().rect_size.x / res_x
		self.rect_size = Vector2(res_x, int(get_parent().rect_size.y / scale))
		$Viewport3D/Scene3D.set_camera_size_factor(self.rect_size.y / res_y)
	else:
		scale = get_parent().rect_size.y / res_y
		self.rect_size = Vector2(int(get_parent().rect_size.x / scale), res_y)
		$Viewport3D/Scene3D.set_camera_size_factor(1.0)
	self.rect_scale = Vector2(scale, scale)
	self.rect_position = (get_parent().rect_size - self.rect_size) * 0.5
	rot_factor = scale


func _on_Sprite_resized() -> void:
	if $Viewport3D/Scene3D.model:
		fit_model()


func _on_PixelDensity_value_changed(value: float) -> void:
	pixel_dens = value
	adjust_viewport()
