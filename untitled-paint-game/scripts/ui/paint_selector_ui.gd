class_name PaintSelectorUI
extends VBoxContainer

@export var paint_textures: Dictionary[PaintColor.Colors, Texture2D]


func _ready() -> void:
	UISignals.selector_changed.connect(_on_selector_changed)
	_update_ui()


func _update_ui() -> void:
	pass


func _on_selector_changed(selector: PaintSelector):
	print("Palette: {%s, is_mixed = %s}" % [PaintColor.Colors.find_key(selector._palette.color), selector._palette.is_mixed])
	var selected_item := %Selection.get_child(0) as TextureRect
	selected_item.texture = paint_textures.get(selector.get_palette_color())
	for slot in %Queue.get_children():
		var item = slot.get_child(0) as TextureRect
		item.texture = paint_textures.get(selector.get_queue_color_at(slot.get_index()))
