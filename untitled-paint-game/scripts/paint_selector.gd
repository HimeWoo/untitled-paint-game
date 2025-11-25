class_name PaintSelector

const STARTING_CAPACITY: int = 3

var selected_index: int = 0
var _colors_used: Array[PaintColor.Colors]
var _queue: Array[QueueElement]
var _capacity: int = STARTING_CAPACITY
var _last_saved_color: PaintColor.Colors = PaintColor.Colors.NONE:
	set(value):
		_last_saved_color = value
		print("LSC: %s" % PaintColor.Colors.find_key(value))



func _init() -> void:
	_queue.clear()
	for i in range(_capacity):
		_queue.push_back(QueueElement.new(PaintColor.Colors.NONE, false))


## Adds the color to selected slot or mixes if different color already exists
func add_color(color: PaintColor.Colors) -> void:
	var selected: QueueElement = get_selection()
	if selected.is_blank():
		selected.color = color
		_colors_used.push_back(color)
		UISignals.selector_changed.emit(self)
	elif selected.color != color:
		var new_color: PaintColor.Colors = PaintColor.mix_colors(color, selected.color)
		selected.color = new_color
		_colors_used.push_back(color)
		UISignals.selector_changed.emit(self)


## Returns the element in the selected slot
func get_selection() -> QueueElement:
	return at(selected_index)


## Returns the element at the specified index
func at(idx: int) -> QueueElement:
	if idx < 0 or idx >= capacity():
		return null
	else:
		return _queue.get(idx)


## Confirms the mixture on palette and moves it to the next queue slot if able
func mix_selected() -> void:
	if not is_queue_full():
		var selected: QueueElement = get_selection()
		var index: int
		for i in range(capacity() - 1):
			index = wrapi(selected_index + i + 1, 0, capacity())
			if at(index).is_blank():
				break
		at(index).color = selected.color
		at(index).is_mixed = true
		selected.color = PaintColor.Colors.NONE
		selected.is_mixed = false
		_colors_used.clear()
		UISignals.selector_changed.emit(self)


## Returns the current mix of colors
func get_colors_used() -> Array[PaintColor.Colors]:
	return _colors_used


## Returns the number of elements in the paint queue
func size() -> int:
	var total: int = 0
	for elem: QueueElement in _queue:
		if not elem.is_blank():
			total += 1
	return total


## Returns the maximum capacity of the paint queue
func capacity() -> int:
	return _capacity


## Returns true if queue is full
func is_queue_full() -> bool:
	return size() >= capacity()


## Undo operations on the selected queue slot
func undo_select_slot() -> void:
	var selected = get_selection()
	if selected.is_mixed:
		selected.color = _last_saved_color
	else:
		selected.color = PaintColor.Colors.NONE
		selected.is_mixed = false
	_colors_used.clear()
	UISignals.selector_changed.emit(self)


func select_next() -> void:
	selected_index = wrapi(selected_index + 1, 0, capacity())
	var new_selection = get_selection()
	if new_selection.is_mixed:
		_last_saved_color = new_selection.color
	UISignals.selector_changed.emit(self)


func select_prev() -> void:
	selected_index = wrapi(selected_index - 1, 0, capacity())
	var new_selection = get_selection()
	if new_selection.is_mixed:
		_last_saved_color = new_selection.color
	UISignals.selector_changed.emit(self)


class QueueElement:
	var color: PaintColor.Colors
	var is_mixed: bool


	func _init(p_color: PaintColor.Colors, p_mixed: bool) -> void:
		color = p_color
		is_mixed = p_mixed
	

	## Returns true this element should be treated as null
	func is_blank() -> bool:
		return color == PaintColor.Colors.NONE
	
