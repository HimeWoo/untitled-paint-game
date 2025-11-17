class_name Inventory

const STARTING_CAPACITY: int = 3

var _contents: Array[PaintColor.Colors]
var _capacity: int = STARTING_CAPACITY


## Returns true if item is successfully added to inventory, false otherwise
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
