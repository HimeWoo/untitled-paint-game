extends RigidBody2D
class_name Pushbox
# The speed the player must reach to move this object
@export var required_velocity: float = 130.0

# How much force to transfer from player to box (adjust for "heaviness")
@export var push_multiplier: float = 1.0

func _ready():
	freeze = true
	linear_damp = 5.0 
	lock_rotation = true 

func attempt_push(pusher_velocity: Vector2):
	# Calculate the speed (magnitude of the vector)
	var current_speed = pusher_velocity.length()
	
	# logic: If player is fast enough, unlock the box
	if current_speed >= required_velocity:
		freeze = false
		
		# Apply an impulse to move it immediately
		# We use central_impulse so it moves based on the player's direction
		apply_central_impulse(pusher_velocity * push_multiplier)

	else:
		# If the player slows down below the threshold, the box becomes a wall again
		freeze = true
