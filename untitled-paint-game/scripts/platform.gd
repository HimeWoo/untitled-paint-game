extends AnimatableBody2D

# This is code I wrote back in April while trying to improve and add functionality to
# the platforms from the brackeys learn godot video. It might also have been some other video tutorial but I'm not too sure.
# The old code may be partially AI generated since I do not remember what I used then.
# The Side to side (fixed) and side to side (collision) are old code I had.
# The side to side with tilemap collision or fixed amount and smart wall distance return is new code.
# Some of this code is modified and was inlcuded with my Exercise 1 submission.
enum MovementMode { STATIONARY, FIXED_PATH, COLLIDE_TILEMAP, SMART_WALL_DIST_COLLIDE, SMART_WALL_DIST_RETURN_START }

@export_enum("Stationary", "Fixed Path", "Side to Side (Collide TileMap)", "Side to Side min(Fixed Dist or Collide TileMap)", "Smart Wall Distance Return to Start")
var movement_mode: int = MovementMode.STATIONARY

@export_enum("Right", "Left")
var start_direction: int = 0  # 0 = right, 1 = left

@export var pixel_offset: int = 64  # Oscillation distance (for fixed path)
@export var speed: float = 50.0     # Movement speed

@onready var ray_left: RayCast2D = $RayCastWallHitLeft
@onready var ray_right: RayCast2D = $RayCastWallHitRight

var direction := 1
var start_position: Vector2
var travel_distance := 0.0

func _ready():
	# Convert to kinematic mode
	PhysicsServer2D.body_set_mode(get_rid(), PhysicsServer2D.BODY_MODE_KINEMATIC)
	start_position = global_position
	direction = 1 if start_direction == 0 else -1

func _physics_process(delta):
	var motion := Vector2.ZERO
			
	#if ray_left.is_colliding():
		#print("left colliding")
	#elif ray_right.is_colliding():
		#print("right colliding")
	
	match movement_mode:
		MovementMode.STATIONARY:
			pass

		# Simple fixed path movement, moves pixel_offset distance before turning around
		MovementMode.FIXED_PATH:
			motion = Vector2(direction * speed * delta, 0)
			global_position += motion
			# Check displacement relative to start and only flip when we've moved
			# `pixel_offset` in the current movement direction.
			var displacement := global_position.x - start_position.x
			if (direction > 0 and displacement >= pixel_offset) or (direction < 0 and displacement <= -pixel_offset):
				direction *= -1

		# Move side to side, reversing direction on tilemap collision
		MovementMode.COLLIDE_TILEMAP:
			if direction < 0 and ray_left.is_colliding():
				direction *= -1
			elif direction > 0 and ray_right.is_colliding():
				direction *= -1

			motion = Vector2(direction * speed * delta, 0)
			global_position += motion

		# Hybrid approach: reverse on wall hit or fixed distance, whichever comes first
		MovementMode.SMART_WALL_DIST_COLLIDE:
			var distance_from_start = abs(global_position.x - start_position.x)
			# Check fixed path limit in the current movement direction only
			var displacement := global_position.x - start_position.x
			var fixed_path_limit_reached := (direction > 0 and displacement >= pixel_offset) or (direction < 0 and displacement <= -pixel_offset)
			var wall_hit = (direction < 0 and ray_left.is_colliding()) or (direction > 0 and ray_right.is_colliding())
			if fixed_path_limit_reached or wall_hit:
				direction *= -1
				travel_distance = 0.0
			motion = Vector2(direction * speed * delta, 0)
			global_position += motion

		# Move until the platform hits the tilemap, then reverse back to start position
		# If it reaches start position, reverse again
		MovementMode.SMART_WALL_DIST_RETURN_START:
			var displacement := global_position.x - start_position.x
			var at_start_position : bool = abs(displacement) < 1.0  # Small threshold
			var wall_hit := (direction < 0 and ray_left.is_colliding()) or (direction > 0 and ray_right.is_colliding())
			if wall_hit:
				direction *= -1
			elif at_start_position:
				# When back at start, resume the configured initial direction
				direction = 1 if start_direction == 0 else -1
			
			motion = Vector2(direction * speed * delta, 0)
			global_position += motion
	
