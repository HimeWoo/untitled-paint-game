class_name PaintQueue
extends RefCounted

var _contents: Array[PaintColor.Colors]
var _selected_index: int = 0 # Default to 0 so we start selected


# CHANGED: Return type is now Variant to allow returning 'null' safely
func current_color() -> Variant:
	if _selected_index >= 0 and _selected_index < _contents.size():
		return _contents[_selected_index]
	return null


func select_index(idx: int) -> bool:
	# Only allow selection if the index actually exists in contents
	if idx == _selected_index:
		return true
	elif idx >= 0 and idx < _contents.size():
		_selected_index = idx
		UISignals.selection_changed.emit(_selected_index)
		print("Selected Slot: ", _selected_index) # Debug print
		return true
	return false


func select_next(dir: int) -> void:
	if _contents.is_empty():
		_selected_index = -1
		return
	var new_index: int = wrapi(_selected_index + dir, 0, _contents.size())
	if new_index == _selected_index:
		return
	UISignals.selection_changed.emit(new_index)
	_selected_index = new_index