class_name WorldItem
extends Area2D

@export var data: ItemData

var is_name_visible: bool = false


func _ready() -> void:
	body_entered.connect(_pickup)


func _pickup(player: Node2D):
	if !player.inventory.is_full():
		player.inventory.add_color(data.color)
		queue_free()
