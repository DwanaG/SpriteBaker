tool
extends Tree

const Tools: Script = preload("tools.gd")

enum Column {PLAY, NAME, CHECK, LOOP, RESTORE_FPS, FPS, LENGTH, FRAMES}

var frame_rate: float = 15.0
var item_playing: TreeItem = null
var anim_player: AnimationPlayer


func _ready() -> void:
	set_column_titles_visible(true)
	set_column_expand(Column.PLAY, false)
	set_column_min_width(Column.PLAY, 30)
	set_column_title(Column.NAME, "Name")
	set_column_min_width(Column.NAME, 60)
	set_column_expand(Column.CHECK, false)
	set_column_min_width(Column.CHECK, 30)
	set_column_expand(Column.LOOP, false)
	set_column_min_width(Column.LOOP, 30)
	set_column_expand(Column.RESTORE_FPS, false)
	set_column_min_width(Column.RESTORE_FPS, 20)
	set_column_title(Column.FPS, "Fps")
	set_column_expand(Column.FPS, false)
	set_column_min_width(Column.FPS, 60)
	set_column_title(Column.LENGTH, "Length")
	set_column_min_width(Column.LENGTH, 60)
	set_column_expand(Column.LENGTH, false)
	set_column_title(Column.FRAMES, "Frames")
	set_column_min_width(Column.FRAMES, 60)
	set_column_expand(Column.FRAMES, false)


func show_model(model: Spatial) -> void:
	clear()
	item_playing = null
	anim_player = Tools.find_single_node_by_type("AnimationPlayer", model)
	if anim_player:
		var anim_list: PoolStringArray = anim_player.get_animation_list()
		if anim_list.size() != 0:
			populate_anim_tree(anim_list)


func clear_model() -> void:
	clear()
	anim_player = null
	item_playing = null


func populate_anim_tree(anim_list: PoolStringArray) -> void:
	var root: TreeItem = create_item()
	for a_name in anim_list:
		var item: TreeItem = create_item(root)

		item.add_button(Column.PLAY, preload("res://addons/sprite-baker/icons/play.svg"), 0)
		item.set_metadata(Column.PLAY, false)
		var splits: PoolStringArray = a_name.split("|")
		var anim_name: String = splits[splits.size() - 1].strip_edges()
		var anim: Animation = anim_player.get_animation(anim_name)
		var is_loop: bool = anim.loop
		if anim_name.ends_with("-loop"):
			anim_name = anim_name.left(anim_name.length() - 5)
			is_loop = true
		item.set_text(Column.NAME, anim_name)
		item.set_metadata(Column.NAME, a_name)
		item.set_cell_mode(Column.CHECK, TreeItem.CELL_MODE_CHECK)
		item.set_checked(Column.CHECK, true)
		item.set_editable(Column.CHECK, true)
		item.set_tooltip(Column.CHECK, "Selected animations will be considered for sprite sheet generation")
		if is_loop:
			item.add_button(Column.LOOP, preload("res://addons/sprite-baker/icons/loop_active.svg"), 0)
			item.set_metadata(Column.LOOP, true)
		else:
			item.add_button(Column.LOOP, preload("res://addons/sprite-baker/icons/loop.svg"), 0)
			item.set_metadata(Column.LOOP, false)
		item.set_tooltip(Column.LOOP, "Animation Looping")
		item.set_metadata(Column.RESTORE_FPS, true)
		item.set_cell_mode(Column.FPS, TreeItem.CELL_MODE_RANGE)
		item.set_range_config(Column.FPS, 1, 60, 1)
		item.set_range(Column.FPS, frame_rate)
		item.set_editable(Column.FPS, true)
		item.set_selectable(Column.FPS, true)
		item.set_tooltip(Column.FPS, "Frames per second")
		item.set_text(Column.LENGTH, "%.2f" % anim.length)
		item.set_text_align(Column.LENGTH, TreeItem.ALIGN_CENTER)
		item.set_tooltip(Column.LENGTH, "Animation lenght (in seconds)")
		var nframes: int = int(round(anim.length * frame_rate)) + 1
		item.set_text(Column.FRAMES, String(nframes))
		item.set_text_align(Column.FRAMES, TreeItem.ALIGN_CENTER)
		item.set_tooltip(Column.FRAMES, "Number of frames")


func set_num_frames(item: TreeItem) -> void:
	var fps: float = item.get_range(Column.FPS)
	var length: float = float(item.get_text(Column.LENGTH))
	var nframes: int = int(round(length * fps)) + 1
	item.set_text(Column.FRAMES, String(nframes))


func play_animation(item: TreeItem) -> void:
	if item.get_metadata(Column.PLAY):
		stop_animation(item, true)
		item_playing = null
	else:
		if item_playing:
			stop_animation(item_playing, false)
		var anim_name: String = item.get_metadata(Column.NAME)
		for node in get_tree().get_nodes_in_group("3D2SS.Model"):
			node.play_animation(anim_name)
		item.set_metadata(Column.PLAY, true)
		item.set_button(Column.PLAY, 0, preload("res://addons/sprite-baker/icons/stop.svg"))
		item_playing = item


func stop_animation(item: TreeItem, back_to_rest: bool) -> void:
	for node in get_tree().get_nodes_in_group("3D2SS.Model"):
		node.stop_animation(back_to_rest)
	item.set_metadata(Column.PLAY, false)
	item.set_button(Column.PLAY, 0, preload("res://addons/sprite-baker/icons/play.svg"))


func _on_item_edited() -> void:
	var item: TreeItem = get_edited()
	var col: int = get_edited_column()
	if col == Column.FPS:
		set_num_frames(item)
		if item.get_metadata(Column.RESTORE_FPS):
			item.add_button(Column.RESTORE_FPS, preload("res://addons/sprite-baker/icons/clear.svg"), 0)
			item.set_metadata(Column.RESTORE_FPS, false)


func _on_button_pressed(item: TreeItem, column: int, _id: int) -> void:
	if column == Column.PLAY:
		play_animation(item)
	elif column == Column.RESTORE_FPS:
		item.erase_button(Column.RESTORE_FPS, 0)
		item.set_metadata(Column.RESTORE_FPS, true)
		item.set_range(Column.FPS, frame_rate)
		set_num_frames(item)
	elif column == Column.LOOP:
		var loop: bool = item.get_metadata(Column.LOOP)
		if loop:
			item.set_button(Column.LOOP, 0, preload("res://addons/sprite-baker/icons/loop.svg"))
		else:
			item.set_button(Column.LOOP, 0, preload("res://addons/sprite-baker/icons/loop_active.svg"))
		loop = not loop
		item.set_metadata(Column.LOOP, loop)
		var anim_name: String = item.get_metadata(Column.NAME)
		for node in get_tree().get_nodes_in_group("3D2SS.Model"):
			var anim = node.get_animation(anim_name)
			anim.loop = loop


func _on_FPS_value_changed(value: float) -> void:
	frame_rate = value
	var item: TreeItem = get_root().get_children()
	while item:
		if item.get_metadata(Column.RESTORE_FPS):
			item.set_range(Column.FPS, value)
			set_num_frames(item)
		item = item.get_next()


func _on_item_activated() -> void:
	play_animation(get_selected())
