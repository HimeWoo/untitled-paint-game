class_name Inventory

const STARTING_CAPACITY: int = 4

var _contents: Dictionary[PaintColor.Colors, int]
var _capacity: int = STARTING_CAPACITY


## Returns true if the color is successfully added to inventory, false otherwise
func add_color(color: PaintColor.Colors) -> bool:
	if size() >= _capacity:
		return false
	_contents.set(color, _contents.get_or_add(color, 0) + 1)
	UISignals.inventory_changed.emit(self)
	return true


## Returns true if item is successfully removed from inventory, false otherwise
func remove_color(color: PaintColor.Colors) -> bool:
	if not has_color(color):
		return false
	_contents.set(color, _contents.get(color) - 1)
	UISignals.inventory_changed.emit(self)
	return true


## Returns true if the inventory contains the specified color
func has_color(color: PaintColor.Colors) -> bool:
	return 0 != _contents.get_or_add(color, 0)


## Returns the amount of the specified color in inventory
func count(color: PaintColor.Colors) -> int:
	return _contents.get_or_add(color, 0)


## Returns the number of items in inventory
func size() -> int:
	var total: int = 0
	for key in _contents:
		total += _contents.get(key)
	return total


## Returns the maximum capacity of the inventory
func capacity() -> int:
	return _capacity


## Returns true if inventory is full
func is_full() -> bool:
	return size() >= capacity()


## Remove all items from inventory
func clear() -> void:
	_contents.clear()
	UISignals.inventory_changed.emit(self)
