extends Node

const STARTING_CAPACITY: int = 3

var _contents: Array[PaintColor]
var _capacity: int = STARTING_CAPACITY


## Returns true if item is successfully added to inventory, false otherwise
func add_color(color: PaintColor) -> bool:
	if _contents.size() < _capacity:
		_contents.append(color)
		return true
	else:
		return false


## Returns true if item is successfully removed from inventory, false otherwise
func remove_color(color: PaintColor) -> bool:
	var index = _contents.find(color)
	if -1 != index:
		_contents.pop_at(index)
		return true
	else:
		return false


## Remove all items from inventory
func clear() -> void:
	_contents.clear()
