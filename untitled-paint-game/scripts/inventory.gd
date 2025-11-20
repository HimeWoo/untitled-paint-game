class_name Inventory

const STARTING_CAPACITY: int = 4

var _contents: Array[PaintColor.Colors]
var _capacity: int = STARTING_CAPACITY
var _selected_index: int = 0 # Default to 0 so we start selected

# CHANGED: Return type is now Variant to allow returning 'null' safely
func current_color() -> Variant:
	if _selected_index >= 0 and _selected_index < _contents.size():
		return _contents[_selected_index]
	return null

func select_index(idx: int) -> bool:
	# Only allow selection if the index actually exists in contents
	if idx >= 0 and idx < _contents.size():
		_selected_index = idx
		print("Selected Slot: ", _selected_index) # Debug print
		return true
	return false

func select_next(dir: int) -> void:
	if _contents.is_empty():
		_selected_index = -1
		return
	_selected_index = wrapi(_selected_index + dir, 0, _contents.size())

# ... (Keep add_color, remove_color, has_color, is_full, clear as they were) ...
# (Just make sure add_color works as written in your snippet)
func add_color(color: PaintColor.Colors) -> bool:
	if _contents.size() < _capacity:
		_contents.append(color)
		return true
	else:
		return false


## Returns true if item is successfully removed from inventory, false otherwise
func remove_color(color: PaintColor.Colors) -> bool:
	var index = _contents.find(color)
	if -1 != index:
		_contents.pop_at(index)
		return true
	else:
		return false


## Returns true if the inventory contains the specified color
func has_color(color: PaintColor.Colors) -> bool:
	return _contents.has(color)


## Returns true if inventory is full
func is_full() -> bool:
	return _contents.size() >= _capacity


## Remove all items from inventory
func clear() -> void:
	_contents.clear()
