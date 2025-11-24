class_name Selector
extends VBoxContainer

@export var selected_texture: Texture2D
@export var deselected_texture: Texture2D
@export var selection: int = 0:
	set(value):
		selection = value
		_update_ui()


func _ready() -> void:
	UISignals.selection_changed.connect(_update_ui)
	_update_ui()


func _update_ui() -> void:
	for idx in range(get_child_count()):
		_deselect(idx)
	_select(selection)
	pass


func _select(idx: int) -> void:
	if idx >= get_child_count() or idx < 0:
		print("_select: Index out of bounds")
		return
	var slot: TextureRect = get_child(idx)
	slot.texture = selected_texture


func _deselect(idx: int) -> void:
	if idx >= get_child_count() or idx < 0:
		print("_deselect: Index out of bounds")
	var slot: TextureRect = get_child(idx)
	slot.texture = deselected_texture



	
