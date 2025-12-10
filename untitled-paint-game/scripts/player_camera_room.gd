class_name PlayerCameraRoom
extends Area2D

## The camera to follow [member target] 
@export var camera: Camera
## The target for [member camera] to follow
@export var target: Node2D
## New smoothing value for [member camera] when entered
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var cam_smoothing: float = 0
## New zoom of the camera when entered
@export_custom(PROPERTY_HINT_LINK, "suffix:") var camera_zoom: Vector2 = Vector2.ZERO
## New zoom speed of the camera when entered
@export var zoom_speed: float = 0
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

func _ready() -> void:
	body_entered.connect(_on_body_entered)


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


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if not camera_zoom.is_zero_approx():
			camera.zoom = camera_zoom
		if not is_zero_approx(zoom_speed):
			camera.zoom_speed = zoom_speed
		if not is_zero_approx(cam_smoothing):
			camera.position_smoothing_speed = cam_smoothing