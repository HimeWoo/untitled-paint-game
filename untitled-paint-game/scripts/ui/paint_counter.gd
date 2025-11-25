class_name PaintCounter
extends Counter

@export var item: ItemData


func _ready() -> void:
	texture = item.texture
	UISignals.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed(inv: Inventory) -> void:
	var new_count: int = inv.count(item.color)
	set_num_icons(new_count)
