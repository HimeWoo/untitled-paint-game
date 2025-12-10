class_name WorldItem
extends Area2D

@export var data: ItemData

var is_name_visible: bool = false


func _ready() -> void:
	body_entered.connect(_pickup)


func _pickup(body: Node2D):
	if body.is_in_group("player"):
		if !body.inventory.is_full():
			body.inventory.add_color(data.color)
			body.play_paint_pickup_sfx()
			queue_free()
