tool
extends Spatial

const Tools: Script = preload("tools.gd")
const AABB_EXTRA_FACTOR: float = 1.05

onready var remote_xform: RemoteTransform = $RemoteTransform
onready var camera: Camera = $Base/Camera
onready var bone: BoneAttachment = $Bone

var model: Spatial setget set_model, get_model
var meshes: Array
var aabb: AABB
var anim_player: AnimationPlayer
var skeleton: Skeleton
var rest_xforms: Array = []
var cam_pos: Vector3


func set_model(new_model: Spatial) -> void:
	if new_model == model:
		return
	if bone.get_parent() != self:
		bone.get_parent().remove_child(bone)
		add_child(bone)
	if remote_xform.get_parent() != self:
		remote_xform.get_parent().remove_child(remote_xform)
		add_child(remote_xform)
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
		if anim_player:
			anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_MANUAL
		skeleton = Tools.find_single_node_by_type("Skeleton", model)
		if skeleton:
			for ibone in range(skeleton.get_bone_count()):
				rest_xforms.append(skeleton.get_bone_global_pose(ibone))
			remove_child(bone)
			skeleton.add_child(bone)
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
	cam_pos = Vector3(posx, posy, 10.0)
	camera.translation = cam_pos
	camera.size = aabb.size.y * AABB_EXTRA_FACTOR


func set_camera_size_factor(f: float) -> void:
	camera.size = aabb.size.y * f * AABB_EXTRA_FACTOR


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
	anim_player.seek(0.0, true)


func stop_animation(back_to_rest: bool) -> void:
	anim_player.stop(true)
	if back_to_rest:
		for ibone in range(skeleton.get_bone_count()):
			skeleton.set_bone_global_pose(ibone, rest_xforms[ibone])


func get_animation(anim_name: String) -> Animation:
	return anim_player.get_animation(anim_name)


func set_animation_loop(anim_name: String, loop: bool) -> void:
	anim_player.get_animation(anim_name).loop = loop


func update_surface_material(surf_name: String, mat: Material) -> void:
	for meshi in meshes:
		var mesh: ArrayMesh = meshi.mesh
		var index: int = mesh.surface_find_by_name(surf_name)
		if index != -1:
			(meshi as MeshInstance).set_surface_material(index, mat)


func set_root_motion_track(root_path: String, id: int) -> void:
	var root: Spatial = model.get_node(root_path)
	remote_xform.get_parent().remove_child(remote_xform)
	if id == -1:
		root.add_child(remote_xform)
		remote_xform.transform = Transform()
	else:
		bone.add_child(remote_xform)
		bone.bone_name = skeleton.get_bone_name(id)
		remote_xform.transform = Transform()
	camera.translation = cam_pos - remote_xform.global_transform.origin
	remote_xform.remote_path = $Base.get_path()


func clear_root_motion_track() -> void:
	remote_xform.get_parent().remove_child(remote_xform)
	add_child(remote_xform)
	remote_xform.transform = Transform()
	remote_xform.remote_path = $Base.get_path()
	$Base.transform = Transform()
	camera.translation = cam_pos


func reset_animation() -> void:
	if anim_player.is_playing():
		anim_player.seek(0.0, true)
