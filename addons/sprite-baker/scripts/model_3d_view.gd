tool
extends "model_viewport.gd"


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if $Viewport3D/Scene3D.model:
			fit_model()


func show_model(model: Spatial) -> void:
	.show_model(model)
	fit_model()


func fit_model() -> void:
	var aabb: AABB = $Viewport3D/Scene3D.aabb
	var mratio: float = aabb.size.x / aabb.size.y
	var ratio: float = self.rect_size.x / self.rect_size.y
	if ratio > mratio:
		$Viewport3D/Scene3D.set_camera_size_factor(1.0)
	else:
		$Viewport3D/Scene3D.set_camera_size_factor(mratio * self.rect_size.y / self.rect_size.x)
