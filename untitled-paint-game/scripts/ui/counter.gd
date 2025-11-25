class_name Counter
extends VBoxContainer

var texture: Texture2D = null


func set_num_icons(new_count: int) -> void:
	var count = %Icons.get_child_count()
	var diff: int = abs(new_count - count)
	if new_count == count:
		return
	elif new_count > count:
		for i in range(diff):
			%Icons.add_child(_init_icon_node())
	elif new_count < count:
		var icons: Array[Node] = %Icons.get_children()
		for i in range(diff):
			(icons.back() as Node).queue_free()


func _init_icon_node() -> TextureRect:
	var ret: TextureRect = TextureRect.new()
	ret.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	if texture == null:
		print("Missing texture for UI counter")
	else:
		ret.texture = texture
	return ret
