class_name Inventory

const STARTING_CAPACITY: int = 4

var _contents: Array[PaintColor.Colors]
var _capacity: int = STARTING_CAPACITY


## Returns true if the color is successfully added to inventory, false otherwise
func add_color(color: PaintColor.Colors) -> bool:
	if _contents.size() < _capacity:
		_contents.push_back(color)
		UISignals.inventory_changed.emit(self)
		return true
	else:
		return false


## Returns true if item is successfully removed from inventory, false otherwise
func remove_color(color: PaintColor.Colors) -> bool:
	var index = _contents.find(color)
	if -1 != index:
		_contents.pop_at(index)
		UISignals.inventory_changed.emit(self)
		return true
	else:
		return false


## 
func at(idx: int) -> Variant:
	return _contents.get(idx)


## Returns true if the inventory contains the specified color
func has_color(color: PaintColor.Colors) -> bool:
	return _contents.has(color)


## Returns the amount of the specified color in inventory
func count(color: PaintColor.Colors) -> int:
	return _contents.count(color)


## Returns the number of items in inventory
func size() -> int:
	return _contents.size()


## Returns the capacity of the inventory
func get_capacity() -> int:
	return _capacity


## Returns true if inventory is full
func is_full() -> bool:
	return _contents.size() >= _capacity


## Remove all items from inventory
func clear() -> void:
	_contents.clear()
	UISignals.inventory_changed.emit(self)
