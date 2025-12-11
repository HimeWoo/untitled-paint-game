extends RigidBody2D
class_name Pushbox

@export var required_velocity: float = 130.0
var start_position: Vector2

func _ready():
	start_position = global_position
	linear_damp = 5.0 
	lock_rotation = true 
	freeze = false  
	sleeping = false
	can_sleep = false 
	add_to_group("pushboxes")

func attempt_push(pusher_velocity: Vector2):
	var current_speed = pusher_velocity.length()
	if current_speed >= required_velocity:
		freeze = false
		apply_central_impulse(pusher_velocity)
	else:
		freeze = true

func reset_to_start() -> void:
	# print statements seem to be NECESSARY to having the box reset properly?
	print("BEFORE RESET: pos=", global_position, " start=", start_position)
	set_physics_process(false)
	freeze = true
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = start_position
	
	print("AFTER SET: pos=", global_position)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	print("AFTER WAIT: pos=", global_position)
	
	freeze = false
	sleeping = false
	set_physics_process(true)
	
	print("FINAL: pos=", global_position)
