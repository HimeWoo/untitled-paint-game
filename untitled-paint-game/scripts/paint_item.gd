class_name PaintItem
extends WorldItem

@export var color: PaintColor.Colors


func _ready() -> void:
	body_entered.connect(_pickup)


func _pickup(player: Node2D):
	if !player.inventory.is_full():
		player.inventory.add_color(color)
		queue_free()
