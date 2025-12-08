class_name PaintSelector

const STARTING_CAPACITY: int = 3

var selected_index: int = 0:
	set(value):
		selected_index = value
		UISignals.selection_changed.emit(selected_index)
		print("Selected: {%s, is_mixed = %s, is_locked = %s}" % [PaintColor.Colors.find_key(get_selection().color), get_selection().is_mixed, get_selection().is_locked])

var _queue: Array[QueueElement]
var _capacity: int = STARTING_CAPACITY:
	set(value):
		UISignals.queue_capacity_changed.emit(_capacity, value)
		_capacity = value

func _init() -> void:
	_queue.clear()
	for i in range(_capacity):
		_queue.push_back(QueueElement.new(PaintColor.Colors.NONE, false))

## Adds the color to selected slot or mixes if different color already exists
func add_color(color: PaintColor.Colors) -> void:
	var selected: QueueElement = get_selection()
	
	# If slot is blank, add the color
	if selected.is_blank():
		selected.color = color
		selected.is_mixed = false
		selected.is_locked = false
		# Track the colors used in THIS slot
		selected.colors_used.push_back(color)
		UISignals.queue_changed.emit(self)
		print("Added ", PaintColor.Colors.find_key(color), " to slot ", selected_index)
	# If slot has a primary color that's different, mix them
	elif PaintColor.is_primary(selected.color) and selected.color != color and not selected.is_locked:
		var new_color: PaintColor.Colors = PaintColor.mix_colors(color, selected.color)
		selected.color = new_color
		selected.is_mixed = false
		selected.is_locked = false
		# Track this new color as used in THIS slot
		selected.colors_used.push_back(color)
		UISignals.queue_changed.emit(self)
		print("Mixed to ", PaintColor.Colors.find_key(new_color), " in slot ", selected_index)

## Returns the element in the selected slot
func get_selection() -> QueueElement:
	return at(selected_index)

## Returns the element at the specified index
func at(idx: int) -> QueueElement:
	if idx < 0 or idx >= capacity():
		return null
	else:
		return _queue.get(idx)

## Confirms the mixture on palette
## This "locks in" the paint, clearing the colors_used and freeing inventory space
func mix_selected() -> void:
	var selected: QueueElement = get_selection()
	
	# Can only confirm mixed colors (not primary colors in hand)
	if selected.is_blank() or PaintColor.is_primary(selected.color):
		return
	
	# Mark as mixed/confirmed and locked
	selected.is_mixed = true
	selected.is_locked = true
	
	# Clear the colors used in THIS slot - this frees up inventory space
	selected.colors_used.clear()
	
	UISignals.queue_changed.emit(self)
	print("Paint confirmed and locked in slot ", selected_index, ". Inventory space freed.")

## Use the paint in the selected slot (for painting tiles/platforms)
## This consumes the paint and frees the slot
func use_selected_paint() -> void:
	var selected: QueueElement = get_selection()
	
	if selected.is_blank():
		return
	
	print("Using paint: ", PaintColor.Colors.find_key(selected.color), " from slot ", selected_index)
	
	# Clear the slot - paint is used
	selected.color = PaintColor.Colors.NONE
	selected.is_mixed = false
	selected.is_locked = false
	selected.colors_used.clear()
	
	UISignals.queue_changed.emit(self)
	print("Paint used. Slot ", selected_index, " freed.")

## Returns the current mix of colors for the SELECTED slot only
func get_colors_used() -> Array[PaintColor.Colors]:
	return get_selection().colors_used

## Returns ALL colors currently being held across all slots (for inventory checking)
func get_all_colors_in_hand() -> Array[PaintColor.Colors]:
	var all_colors: Array[PaintColor.Colors] = []
	for elem in _queue:
		if not elem.is_locked:  # Only count unlocked (in-hand) paints
			all_colors.append_array(elem.colors_used)
	return all_colors

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

## Clear selected slot and free inventory space
func clear_selection() -> void:
	var selected = get_selection()
	
	selected.color = PaintColor.Colors.NONE
	selected.is_mixed = false
	selected.is_locked = false
	selected.colors_used.clear()
	
	UISignals.queue_changed.emit(self)
	print("Cleared slot ", selected_index)

## Change selection to the next slot
func select_next() -> void:
	selected_index = wrapi(selected_index + 1, 0, capacity())

## Change selection to the previous slot
func select_prev() -> void:
	selected_index = wrapi(selected_index - 1, 0, capacity())

class QueueElement:
	var color: PaintColor.Colors
	var is_mixed: bool
	var is_locked: bool = false
	var colors_used: Array[PaintColor.Colors] = []  # NEW: Track colors used PER SLOT
	
	func _init(p_color: PaintColor.Colors, p_mixed: bool) -> void:
		color = p_color
		is_mixed = p_mixed
		is_locked = false
		colors_used = []
	
	## Returns true this element should be treated as null
	func is_blank() -> bool:
		return color == PaintColor.Colors.NONE
