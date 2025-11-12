class_name WorldItem
extends Area2D

@export var item: Resource

var is_name_visible: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node2D) -> void:
	queue_free()