class_name PaintQueue

const STARTING_CAPACITY: int = 3

var _contents: Array[PaintColor.Colors]
var _capacity: int = STARTING_CAPACITY

var _selected_index: int = 0: # Default to 0 so we start selected
	set(value):
		if _selected_index != value:
			_selected_index = value
			UISignals.selection_changed.emit(value)

func add_color(color: PaintColor.Colors) -> void:	
	var selected = get_selected_color()
	if null == selected:
		_contents.push_front(color)
		UISignals.paint_queue_changed.emit(self)
	elif color != selected:
		_contents.pop_front()
		_contents.push_front(_mix_colors(color, selected))
		UISignals.paint_queue_changed.emit(self)


func get_selected_color() -> Variant:
	if 0 > _selected_index or _selected_index >= _contents.size():
		return null
	else:
		return _contents.get(_selected_index)


func get_capacity() -> int:
	return _capacity


## Implement this somewhere idk
func _mix_colors(color1: PaintColor.Colors, color2: PaintColor.Colors) -> PaintColor.Colors:
	if color1 == PaintColor.Colors.RED and color2 == PaintColor.Colors.YELLOW:
		return PaintColor.Colors.ORANGE
	return PaintColor.Colors.BLACK