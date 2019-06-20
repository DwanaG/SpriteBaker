tool
extends Node

const Tools: Script = preload("tools.gd")

var scene_3d: Spatial

var keys: Array
var nframe: int
var sprites: Array = []
var anim_name: String


func _ready() -> void:
	scene_3d = $Viewport3D/Scene3D
	set_process(false)


func _process(_delta: float) -> void:
	var texture: = ImageTexture.new()
	texture.create_from_image($Viewport3D.get_texture().get_data(), 0)
	sprites.append(texture)
	nframe += 1
	if nframe == keys.size():
		make_sprite_sheet()
		set_process(false)
	else:
		scene_3d.anim_player.seek(keys[nframe], true)


#func get_scene_3d() -> Spatial:
#	return scene_3d


func bake_animation(anim_name_: String, pixel_dens: float, margin: float, keys_: Array) -> void:
	var aabb: AABB = scene_3d.aabb
	var res_x = int(ceil(aabb.size.x * pixel_dens)) + 2 * margin
	var res_y = int(ceil(aabb.size.y * pixel_dens)) + 2 * margin
	scene_3d.camera.size += 2.0 * margin / pixel_dens
	$Viewport3D.size = Vector2(res_x, res_y)
	keys = keys_
	anim_name = anim_name_
	scene_3d.play_animation(anim_name)
	nframe = 0
	scene_3d.anim_player.seek(keys[0], true)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	set_process(true)


func make_sprite_sheet() -> void:
	Tools.clear_node($SpriteSheet)
	var size: Vector2 = (sprites[0] as ImageTexture).get_size()
	var n: int = int(ceil(sqrt(sprites.size())))
	$SpriteSheet.size = Vector2(size.x * n, size.y * n)
	for i in range(sprites.size()):
		var rect: = TextureRect.new()
		$SpriteSheet.add_child(rect)
		rect.rect_size = size
		rect.texture = sprites[i]
		var x: float = (i % n) * size.x
		var y: float = int(i / float(n)) * size.y
		rect.rect_position = Vector2(x, y)
	yield(get_tree(), "idle_frame")
	var path: String = scene_3d.model.get_meta("resource_path").get_base_dir()
	path += "/" + anim_name + ".png"
	var texture: = ImageTexture.new()
	texture.create_from_image($SpriteSheet.get_texture().get_data())
	assert(ResourceSaver.save(path, texture, 0) == OK)
	scene_3d.set_model(null)
