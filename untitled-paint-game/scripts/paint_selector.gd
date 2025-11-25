class_name PaintSelector

const STARTING_QUEUE_CAPACITY: int = 2 # Slots beyond the first given by default

var _palette: QueueElement = QueueElement.new(PaintColor.Colors.NONE, false)
var _colors_used: Array[PaintColor.Colors]
var _queue: Array[QueueElement]
var _capacity: int = STARTING_QUEUE_CAPACITY


## Adds the color to the palette or preview mix if a different color already exists
func add_color_to_palette(color: PaintColor.Colors) -> void:
	if _palette.color == PaintColor.Colors.NONE:
		_palette.color = color
		_colors_used.push_back(color)
		UISignals.selector_changed.emit(self)
	elif _palette.color != color:
		var new_color: PaintColor.Colors = PaintColor.mix_colors(color, _palette.color)
		_palette.color = new_color
		_colors_used.push_back(color)
		UISignals.selector_changed.emit(self)


## Returns the color in the palette
func get_palette_color() -> PaintColor.Colors:
	return _palette.color


## Returns the color at the specified index in the queue
func get_queue_color_at(idx: int) -> PaintColor.Colors:
	if idx < 0 or idx >= queue_size():
		return PaintColor.Colors.NONE
	else:
		return _queue.get(idx).color


## Confirms the mixture on palette and moves it to the next queue slot if able
func mix_palette() -> void:
	if not is_queue_full():
		_queue.push_front(QueueElement.new(_palette.color, true))
		_palette.color = PaintColor.Colors.NONE
		_palette.is_mixed = false
		_colors_used.clear()
		UISignals.selector_changed.emit(self)


## Returns the current mix of colors
func get_colors_used() -> Array[PaintColor.Colors]:
	return _colors_used


## Returns the number of elements in the paint queue
func queue_size() -> int:
	return _queue.size()


## Returns the maximum capacity of the paint queue
func queue_capacity() -> int:
	return _capacity


## Returns true if queue is full
func is_queue_full() -> bool:
	return queue_size() >= queue_capacity()


## Clear selected queue slot
func clear_selected() -> void:
	_palette.color = PaintColor.Colors.NONE
	_palette.is_mixed = false
	_colors_used.clear()
	UISignals.selector_changed.emit(self)


## Load paint from the specified index onto the palette
func load_to_palette(idx: int):
	if queue_size() > 0:
		var swap_out: QueueElement = _queue.pop_at(idx)
		if _palette.is_mixed:
			_queue.insert(idx, QueueElement.new(_palette.color, true))
		else:
			_colors_used.clear()
		_palette.color = swap_out.color
		_palette.is_mixed = swap_out.is_mixed
		print("Palette swap in: {%s, is_mixed = %s}" % [PaintColor.Colors.find_key(swap_out.color), swap_out.is_mixed])
		UISignals.selector_changed.emit(self)


class QueueElement:
	var color: PaintColor.Colors
	var is_mixed: bool


	func _init(p_color: PaintColor.Colors, p_mixed: bool) -> void:
		color = p_color
		is_mixed = p_mixed
	