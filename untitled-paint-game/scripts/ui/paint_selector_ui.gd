class_name PaintSelectorUI
extends VBoxContainer

@export var paint_textures: Dictionary[PaintColor.Colors, Texture2D]
@export var selected_slot: Texture2D
@export var deselected_slot: Texture2D


func _ready() -> void:
	UISignals.selector_changed.connect(_on_selector_changed)


func select(idx: int) -> void:
	var slot = get_child(idx)
	slot.texture = selected_slot


func deselect(idx: int) -> void:
	var slot = get_child(idx)
	slot.texture = deselected_slot


func _on_selector_changed(selector: PaintSelector):
	for slot in get_children():
		deselect(slot.get_index())
		var item = slot.get_child(0) as TextureRect
		item.texture = paint_textures.get(selector.at(slot.get_index()).color)
	select(selector.selected_index)
