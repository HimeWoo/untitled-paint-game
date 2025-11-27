class_name PaintSelectorUI
extends VBoxContainer

@export var queue_slot: PackedScene = preload("res://scenes/ui/queue_slot.tscn")

@export var paint_textures: Dictionary[PaintColor.Colors, Texture2D]
@export var selected_slot: Texture2D
@export var deselected_slot: Texture2D
@export var num_slots: int = 3


func _ready() -> void:
	for i in range(num_slots):
		add_child(queue_slot.instantiate())
	if num_slots > 0:
		select(0)
	UISignals.queue_changed.connect(_on_queue_changed)
	UISignals.selection_changed.connect(_on_selection_changed)
	UISignals.queue_capacity_changed.connect(_on_queue_capacity_changed)


func select(idx: int) -> void:
	var slot = get_child(idx)
	slot.texture = selected_slot


func deselect(idx: int) -> void:
	var slot = get_child(idx)
	slot.texture = deselected_slot


func _on_queue_changed(queue: PaintSelector):
	for slot in get_children():
		var item = slot.get_child(0) as TextureRect
		item.texture = paint_textures.get(queue.at(slot.get_index()).color)


func _on_selection_changed(idx: int):
	for i in range(get_child_count()):
		deselect(i)
	select(idx)


func _on_queue_capacity_changed(old_count: int, new_count: int):
	var diff: int = abs(new_count - old_count)
	if new_count > old_count:
		for i in range(diff):
			add_child(queue_slot.instantiate())
	else:
		var slots: Array[Node] = get_children()
		for i in range(diff):
			(slots.back() as Node).queue_free()
