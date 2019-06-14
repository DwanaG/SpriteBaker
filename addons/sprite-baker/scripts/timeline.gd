tool
extends VBoxContainer

signal time_changed(time)
signal animation_finished

const Tools: Script = preload("tools.gd")

export(StyleBox) var tick_style: StyleBox
export(NodePath) var time_ruler_path: NodePath
export(NodePath) var slider_path: NodePath
export(NodePath) var background_path: NodePath

onready var time_ruler: BoxContainer = get_node(time_ruler_path)
onready var slider: Slider = get_node(slider_path)
onready var background: Slider = get_node(background_path)

var max_length: float = 0.0
var anim_length: float = 0.0
var time: float = 0.0
var playing: bool = false
var paused: bool = false
var looping: bool = false


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	time += delta
	var finished: bool = false
	if looping:
		time = fmod(time, anim_length)
	elif time >= anim_length:
		finished = true
		time = anim_length
	for node in get_tree().get_nodes_in_group("3D2SS.Model"):
		node.anim_player.seek(time, true)
	slider.value = time
	if finished:
		set_physics_process(false)
		time = 0.0
		paused = true
		emit_signal("animation_finished")


func clear() -> void:
	playing = false
	paused = false
	anim_length = 0.0
	max_length = 0.0
	background.update()
	set_physics_process(false)


func play_animation(length: float, loop: bool) -> void:
	if Tools.is_node_being_edited(self):
		return
	Tools.clear_node(time_ruler)
	anim_length = length
	looping = loop
	var a: Array = get_timeline_length(anim_length)
	max_length = a[0]
	var nticks: int = a[1]
	slider.max_value = max_length
	slider.tick_count = nticks
	slider.editable = true
	slider.value = 0.0
	time = 0.0
	for itick in range(nticks):
		if itick != 0:
			var separator: = VSeparator.new()
			separator.add_stylebox_override("separator", tick_style)
			separator.size_flags_horizontal = SIZE_EXPAND_FILL
			time_ruler.add_child(separator)
		var label: = Label.new()
		var t: float = float(itick) * max_length / float(nticks - 1)
		label.text = "%.1f" % t
		if t > anim_length:
			label.add_color_override("font_color", Color(0.5, 0.5, 0.5))
		time_ruler.add_child(label)
	background.update()
	set_physics_process(true)
	playing = true
	paused = false


func stop_animation(back_to_rest: bool) -> void:
	playing = false
	paused = false
	if back_to_rest:
		anim_length = 0.0
		max_length = 0.0
		background.update()
		for child in time_ruler.get_children():
			if child is Label:
				child.add_color_override("font_color", Color(0.5, 0.5, 0.5))
		slider.editable = false
		slider.value = 0.0
		set_physics_process(false)


func reset_animation() -> void:
	time = 0.0
	slider.value = 0.0


func pause_animation() -> void:
	set_physics_process(false)
	paused = true


func resume_animation() -> void:
	set_physics_process(true)
	paused = false


func set_time(value: float) -> void:
	slider.value = value


func get_timeline_length(anim_lenght: float) -> Array:
	var step: float
	if anim_lenght < 0.6:
		step = 0.1
	if anim_lenght < 1.6:
		step = 0.5
	elif anim_lenght < 6.0:
		step = 1.0
	elif anim_lenght < 16.0:
		step = 2.0
	elif anim_lenght < 35.0:
		step = 5.0
	elif anim_lenght < 100.0:
		step = 10.0
	else:
		step = 50.0
	var length: float = stepify(anim_lenght + step * 0.5, step)
	return [length, int(length / step) + 1]


func _on_Background_draw() -> void:
	if playing:
		var width: float = background.rect_size.x * anim_length / max_length
		var rect: = Rect2(Vector2(0, 0), Vector2(width, background.rect_size.y))
		background.draw_rect(rect, Color(0.26, 0.31, 0.40), true)


func _on_Slider_value_changed(value: float) -> void:
	if not playing:
		return
	if value > anim_length:
		slider.value = anim_length
	time = slider.value
	emit_signal("time_changed", time)
	if paused:
		for node in get_tree().get_nodes_in_group("3D2SS.Model"):
			node.anim_player.seek(time, true)

