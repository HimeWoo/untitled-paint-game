extends RigidBody2D
class_name Pushbox

@export var required_velocity: float = 130.0

# Called when the node enters the scene tree for the first time.
func _ready():
	freeze = true
	linear_damp = 5.0 
	lock_rotation = true 


func attempt_push(pusher_velocity: Vector2):
	var current_speed = pusher_velocity.length()
	if current_speed >= required_velocity:
		freeze = false

		apply_central_impulse(pusher_velocity)

	else:
		# If the player slows down below the threshold, the box becomes a wall again
		freeze = true
