class_name PaintQueue

const STARTING_CAPACITY: int = 3

var _contents: Array[PaintColor.Colors]
var _capacity: int = STARTING_CAPACITY
var selected_index: int = 0: # Default to 0 so we start selected
	set(value):
		if selected_index != value:
			selected_index = value
			UISignals.selection_changed.emit(value)


func add_color(color: PaintColor.Colors) -> void:	
	var selected = at(selected_index)
	if selected == PaintColor.Colors.NONE:
		_contents.push_front(color)
		UISignals.paint_queue_changed.emit(self)
	elif selected != color:
		_contents.pop_front()
		_contents.push_front(PaintColor.mix_colors(color, selected))
		UISignals.paint_queue_changed.emit(self)


## Returns the color at the specified index
func at(idx: int) -> PaintColor.Colors:
	if 0 > idx or idx >= _contents.size():
		return PaintColor.Colors.NONE
	else:
		return _contents.get(idx)


## Clear selected queue slot
func clear() -> void:
	if _contents.size() > 0:
		_contents.clear()
		UISignals.paint_queue_changed.emit(self)


func get_capacity() -> int:
	return _capacity
