tool
extends Spatial

const Tools: Script = preload("tools.gd")
const AABB_EXTRA_FACTOR: float = 1.05

var model: Spatial setget set_model, get_model
var meshes: Array
var aabb: AABB
var anim_player: AnimationPlayer
var skeleton: Skeleton
var rest_xforms: Array = []


func set_model(new_model: Spatial) -> void:
	if new_model == model:
		return
	if model != null:
		remove_child(model)
		model.queue_free()
	model = new_model
	if model == null:
		meshes = []
		anim_player = null
		skeleton = null
		rest_xforms = []
	else:
		add_child(model)
		meshes = Tools.find_nodes_by_type("MeshInstance", model)
		anim_player = Tools.find_single_node_by_type("AnimationPlayer", model)
		skeleton = Tools.find_single_node_by_type("Skeleton", model)
		if skeleton:
			for ibone in range(skeleton.get_bone_count()):
				rest_xforms.append(skeleton.get_bone_global_pose(ibone))
		get_meshes_aabb()
	adjust_camera()


func get_model() -> Spatial:
	return model


func get_meshes_aabb() -> void:
	if meshes.size() == 0:
		aabb = AABB(Vector3.ZERO, Vector3.ONE)
		return
	aabb = meshes[0].get_transformed_aabb()
	for iMesh in range(1, meshes.size()):
		aabb = aabb.merge(meshes[iMesh].get_transformed_aabb())


func adjust_camera() -> void:
	var posx: float = aabb.position.x + aabb.size.x * 0.5
	var posy: float = aabb.position.y + aabb.size.y * 0.5
	$Camera.translation = Vector3(posx, posy, 10.0)
	$Camera.size = aabb.size.y * AABB_EXTRA_FACTOR


func set_camera_size_factor(f: float) -> void:
	$Camera.size = aabb.size.y * f * AABB_EXTRA_FACTOR



func rotate_model(rotx: float, roty: float) -> void:
	var model_scale = model.scale
	model.transform.basis = Basis() # reset rotation
	model.rotate_object_local(Vector3(0, 1, 0), rotx) # first rotate in Y
	model.rotate_object_local(Vector3(1, 0, 0), roty) # then rotate in X
	var basis: Basis = model.transform.basis
	var aabb_center: Vector3 = Vector3(aabb.position.x + aabb.size.x * 0.5,
										aabb.position.y + aabb.size.y * 0.5,
										aabb.position.z + aabb.size.z * 0.5)
	var center: Vector3 = basis.x * aabb_center.x + basis.y * aabb_center.y + basis.z * aabb_center.z
	model.transform.origin = aabb_center - center
	model.scale = model_scale


func play_animation(anim_name: String) -> void:
	anim_player.play(anim_name)


func stop_animation(back_to_rest: bool) -> void:
	anim_player.stop(true)
	if back_to_rest:
		for ibone in range(skeleton.get_bone_count()):
			skeleton.set_bone_global_pose(ibone, rest_xforms[ibone])

