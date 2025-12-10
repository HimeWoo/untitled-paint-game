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
@export var camera: Camera2D
## New zoom of the camera when triggered
@export_custom(PROPERTY_HINT_LINK, "suffix:") var camera_zoom: Vector2 = Vector2.ZERO
## New position the camera moves toward when triggered
@export var camera_target: Vector2 = Vector2.ZERO
## If true, entering sets a player checkpoint at entry
@export var set_checkpoint_on_enter: bool = true
## Area2D representing the room bounds for paint reset (optional)
@export var room_area_for_checkpoint: Area2D
## Optional: explicit spawn marker to use for respawn
@export var checkpoint_spawn: Node2D

@export var follow_player: bool = false

## PARALLAX SECTION STUFF
@export var show_background: bool = false 
@onready var bg_group = $"/root/World/ParallaxSection"

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player") and _entered_from_valid_direction(body):
		if show_background:
			print("parallax trigger hit...")
			bg_group.show()
		else:
			bg_group.hide()
		
		if not follow_player:
			if camera:
				camera.make_current()
			if not camera_target == null:
				camera.position = camera_target
			if not camera_zoom.is_zero_approx():
				camera.target_zoom = camera_zoom
			# Apply scripted velocity here

			var allow_checkpoint := true
			allow_checkpoint = body.can_set_checkpoint()
			if set_checkpoint_on_enter and allow_checkpoint:
				var area_name ="unknown"
				if room_area_for_checkpoint != null:
					area_name = room_area_for_checkpoint.name
				var spawn_pos := global_position
				if checkpoint_spawn != null and is_instance_valid(checkpoint_spawn):
					spawn_pos = checkpoint_spawn.global_position
				print("RoomTransition name=", name, " Position=", spawn_pos, " room_area=",area_name)
				body.set_room_checkpoint(spawn_pos, room_area_for_checkpoint)
		else:
			# Switch to the assigned Follow Camera
			print("Switched to player follow camera")
			if camera:
				camera.make_current()
				# Optional: Apply zoom settings if you set them on this transition
				if not camera_zoom.is_zero_approx():
					# Check if your camera script uses 'target_zoom' (custom) or standard 'zoom'
					if "target_zoom" in camera:
						camera.target_zoom = camera_zoom
					else:
						camera.zoom = camera_zoom

## Returns true if the body entered from a direction in enter_directions
func _entered_from_valid_direction(body: Node2D) -> bool:
	return (enter_directions.has(Direction.LEFT) and body.position.x < position.x)\
			or (enter_directions.has(Direction.RIGHT) and body.position.x > position.x)\
			or (enter_directions.has(Direction.TOP) and body.position.y < position.y)\
			or (enter_directions.has(Direction.BOTTOM) and body.position.y > position.y)
