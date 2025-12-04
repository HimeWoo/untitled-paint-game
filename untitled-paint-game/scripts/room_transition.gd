class_name RoomTransition
extends Area2D


enum Direction {
	LEFT,
	TOP,
	RIGHT,
	BOTTOM,
}

## List of directions that the player can enter from to trigger the transition
@export var enter_directions: Array[Direction]
## Velocity given to the player when the transition is triggered
@export var scripted_velocity: Vector2
## The camera to move when triggered
@export var camera: Camera
## New zoom of the camera when triggered
@export var camera_zoom: Vector2
## New position the camera moves toward when triggered
@onready var camera_target: Node2D = $CameraTarget


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player") and _entered_from_valid_direction(body):
		if not camera_target == null:
			camera.position = camera_target.global_position
		if not camera_zoom.is_zero_approx():
			camera.target_zoom = camera_zoom
		# Apply scripted velocity here


## Returns true if the body entered from a direction in enter_directions
func _entered_from_valid_direction(body: Node2D) -> bool:
	return (enter_directions.has(Direction.LEFT) and body.position.x < position.x)\
			or (enter_directions.has(Direction.RIGHT) and body.position.x > position.x)\
			or (enter_directions.has(Direction.TOP) and body.position.y < position.y)\
			or (enter_directions.has(Direction.BOTTOM) and body.position.y > position.y)
