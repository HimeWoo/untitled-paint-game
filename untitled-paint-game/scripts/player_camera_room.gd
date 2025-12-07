class_name PlayerCameraRoom
extends Area2D

## The camera to follow [member target] 
@export var camera: Camera
## The target for [member camera] to follow
@export var target: Node2D
## The area [member camera] is allowed to move in
@export var camera_area: CollisionShape2D
## If true then [member camera]'s x position will be constant with value [member locked_x_value]
@export var lock_x: bool = false
## The x position [member camera] will be locked to if [member lock_x] is true 
@export var locked_x_value: float = 0
## If true then [member camera]'s y position will be constant with value [member locked_y_value]
@export var lock_y: bool = false
## The y position [member camera] will be locked to if [member lock_y] is true
@export var locked_y_value: float = 0

@onready var _rect_pos: Vector2 = camera_area.shape.get_rect().position + camera_area.global_position
@onready var _rect_end: Vector2 = camera_area.shape.get_rect().end + camera_area.global_position


func _process(_delta: float) -> void:
	if overlaps_body(target):
		var camera_x: float
		if lock_x:
			camera_x = locked_x_value
		elif target.position.x < _rect_pos.x:
			camera_x = _rect_pos.x
		elif target.position.x > _rect_end.x:
			camera_x = _rect_end.x
		else:
			camera_x = target.position.x
		
		var camera_y: float
		if lock_y:
			camera_y = locked_y_value
		elif target.position.y < _rect_pos.y:
			camera_y = _rect_pos.y
		elif target.position.y > _rect_end.y:
			camera_y = _rect_pos.y
		else:
			camera_y = target.position.y

		camera.position = Vector2(camera_x, camera_y)
