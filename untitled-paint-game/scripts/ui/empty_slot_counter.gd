class_name EmptySlotCounter
extends VBoxContainer

@export var texture: Texture2D
@export var count: int = 0:
	set(value):
		count = value
		_update_ui()


func _ready() -> void:
	UISignals.inventory_changed.connect(_on_inventory_changed)
	_update_ui()


## Update the number of icons to match `count`
func _update_ui() -> void:
	var prev_count: int = %Icons.get_child_count()
	var diff: int = abs(count - prev_count)
	if count > prev_count:
		for i in range(diff):
			%Icons.add_child(_init_icon_node())
	else:
		var icons: Array[Node] = %Icons.get_children()
		for i in range(diff):
			(icons.back() as Node).queue_free()


func _init_icon_node() -> TextureRect:
	var ret: TextureRect = TextureRect.new()
	ret.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	ret.texture = texture
	return ret


func _on_inventory_changed(inv: Inventory) -> void:
	var new_count: int = inv.capacity() - inv.size()
	if new_count != count:
		count = new_count
