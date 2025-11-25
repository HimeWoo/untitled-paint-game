class_name EmptySlotCounter
extends Counter

@export var empty_slot_texture: Texture2D


func _ready() -> void:
	texture = empty_slot_texture
	UISignals.inventory_changed.connect(_on_inventory_changed)
	set_num_icons(Inventory.STARTING_CAPACITY)


func _on_inventory_changed(inv: Inventory) -> void:
	var new_count: int = inv.capacity() - inv.size()
	set_num_icons(new_count)
