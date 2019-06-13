tool
extends Node

const Tools: Script = preload("tools.gd")
const DEF_FRAME_RATE: float = 15.0

export(NodePath) var preview_path: NodePath
export(NodePath) var reference_scene_path: NodePath
export(NodePath) var pixel_dens_path: NodePath
export(NodePath) var margin_path: NodePath
export(NodePath) var progress_path: NodePath
export(NodePath) var tabs_path: NodePath
export(NodePath) var info_path: NodePath
export(NodePath) var generate_button_path: NodePath
export(NodePath) var animations_tree_path: NodePath

onready var preview: TextureRect = get_node(preview_path)
onready var reference: Spatial = get_node(reference_scene_path)
onready var pixel_dens: SpinBox = get_node(pixel_dens_path)
onready var progress: ProgressBar = get_node(progress_path)
onready var tabs: TabContainer = get_node(tabs_path)
onready var info: Label = get_node(info_path)
onready var anim_tree: Tree = get_node(animations_tree_path)

onready var frame_rate: float = DEF_FRAME_RATE

var info_txt: String = ""
var anim_player: AnimationPlayer
var nanims: int = 0
var base_name: String = ""
var total_count: int
var current_count: int
var halt_timer: bool = false
var queue_timer: bool = false


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	progress.value = current_count / float(total_count)


func adjust_viewport(pixel_density: float) -> void:
	var aabb: AABB = $Scene3D/GenScene.aabb
	var resx: int = int(ceil(aabb.size.x * pixel_density))
	var resy: int = int(ceil(aabb.size.y * pixel_density))
	$Scene3D.size = Vector2(resx, resy)
	$Scene3D/GenScene.adjust_camera()


func gen_sprite() -> void:
	var texture: = ImageTexture.new()
	texture.create_from_image($Scene3D.get_texture().get_data(), 0)
	preview.set_texture(texture)

	progress.value = 1.0
	yield(get_tree(), "idle_frame")
	progress.value = 0.0

	info_txt = "Size: %dx%d pixels" % [texture.get_width(), texture.get_height()]
	info_txt += " | Animations: %d" % nanims
	show_info()


func start_timer() -> void:
	if halt_timer:
		queue_timer = true
		return
	$Timer.start()
	progress.value = 0.0
	yield(get_tree(), "idle_frame")
	progress.value = 0.25
	info_txt = "(Updating sprite)"
	show_info()


func clear() -> void:
	preview.set_texture(null)
	info_txt = ""
	get_node(generate_button_path).disabled = true
	anim_tree.hide()


func show_info() -> void:
	if tabs.current_tab == 1:
		info.text = info_txt


func make_sprite_sheet(sprites: Array) -> void:
	var size: Vector2 = (sprites[0] as ImageTexture).get_size()
	$SpriteSheet.size = Vector2(size.x * sprites.size(), size.y)
	for i in range(sprites.size()):
		var rect: = TextureRect.new()
		$SpriteSheet.add_child(rect)
		rect.rect_size = size
		rect.texture = sprites[i]
		rect.rect_position = Vector2(size.x * i, 0.0)


func save_sprite_sheet(anim_name: String) -> void:
	var path: String = anim_name + ".png"
	var texture: = ImageTexture.new()
	texture.create_from_image($SpriteSheet.get_texture().get_data())
	assert(ResourceSaver.save(path, texture, 0) == OK)


func _on_outdated_sprite() -> void:
	start_timer()


func _on_outdated_model() -> void:
	var model: Spatial = reference.model.duplicate()
	var path: String = model.get_meta("path")
	base_name = path.get_basename()
	$Scene3D/GenScene.model = model
	anim_player = Tools.find_single_node_by_type("AnimationPlayer", model)
	nanims = 0 if !anim_player else anim_player.get_animation_list().size()
	if nanims == 0:
		get_node(generate_button_path).disabled = true
		anim_tree.clear()
		anim_tree.hide()
	else:
		anim_player.playback_active = false
		anim_tree.populate_anim_tree(anim_player, frame_rate)
		get_node(generate_button_path).disabled = false
		anim_tree.show()

	adjust_viewport(pixel_dens.value)
	start_timer()


func _on_Timer_timeout() -> void:
	gen_sprite()


func _on_Pixels_value_changed(_value: float) -> void:
	adjust_viewport(pixel_dens.value)
	start_timer()


func _on_TabContainer_tab_changed(_tab: int) -> void:
	show_info()


func _on_Generate_pressed():
	halt_timer = true
	var cam_size: float = $Scene3D/GenScene/Camera.size
	var vp_size: Vector2 = $Scene3D.size
	var margin: int = get_node(margin_path).value
	$Scene3D/GenScene/Camera.size = cam_size + 2.0 * margin / pixel_dens.value
	$Scene3D.size = Vector2(vp_size.x + 2 * margin, vp_size.y + 2 * margin)

	var data: Dictionary = anim_tree.get_data()
	var anim_names: PoolStringArray = anim_player.get_animation_list()
	# Count steps
	total_count = 0
	for index in data:
		var anim: Animation = anim_player.get_animation(anim_names[index])
		var anim_data: Dictionary = data[index]
		total_count += int(round(anim.length * anim_data["fps"])) + 1
	set_process(true)

	# Generate sprite sheets
	current_count = 0
	for index in data:
		Tools.clear_node($SpriteSheet)
		var anim_name: String = anim_names[index]
		anim_player.play(anim_name)
		var anim: Animation = anim_player.get_animation(anim_name)
		var anim_data: Dictionary = data[index]
		var nframes: int = int(round(anim.length * anim_data["fps"])) + 1
		var sprites: Array = []
		for iframe in range(nframes):
			anim_player.seek(iframe * anim.length / (nframes - 1.0), true)
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			var texture: = ImageTexture.new()
			texture.create_from_image($Scene3D.get_texture().get_data(), 0)
			sprites.append(texture)
			current_count += 1
		make_sprite_sheet(sprites)
		yield(get_tree(), "idle_frame")
		save_sprite_sheet(base_name + "_" + anim_data["name"])

	set_process(false)
	progress.value = 1.0
	yield(get_tree(), "idle_frame")
	progress.value = 0.0
	$Scene3D/GenScene/Camera.size = cam_size
	$Scene3D.size = vp_size

	halt_timer = false
	if queue_timer:
		queue_timer = false
		start_timer()


func _on_AnimationsTree_available_animations(available: bool) -> void:
	get_node(generate_button_path).disabled = not available
