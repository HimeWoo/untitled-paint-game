extends AnimatableBody2D

# This is code I wrote back in April while trying to improve and add functionality to
# the platforms from the brackeys learn godot video. It might also have been some other video tutorial but I'm not too sure.
# The old code may be partially AI generated since I do not remember what I used then.
# The Side to side (fixed) and side to side (collision) are old code I had.
# The side to side with tilemap collision or fixed amount and smart wall distance return is new code.
# Some of this code is modified and was inlcuded with my Exercise 1 submission.
enum MovementMode { STATIONARY, FIXED_PATH, COLLIDE_TILEMAP, SMART_WALL_DIST_COLLIDE, SMART_WALL_DIST_RETURN_START, FIXED_PATH_VERTICAL, GO_TO_TARGET_RETURN_START }

@export_enum("Stationary", "Fixed Path (Horizontal)", "Side to Side (Collide TileMap)", "Side to Side min(Fixed Dist or Collide TileMap)", "Smart Wall Distance Return to Start", "Fixed Path (Vertical)", "Go To Target (Return Start)")
var movement_mode: int = MovementMode.STATIONARY

@export_enum("Right", "Left")
var start_direction: int = 0  # 0 = right, 1 = left

@export var pixel_offset: int = 64  # Oscillation distance (for fixed path)
@export var speed: float = 50.0     # Movement speed
@export var target_global: Vector2 = Vector2.ZERO  # Destination for GO_TO_TARGET_RETURN_START
@export var reach_threshold: float = 1.0           # Threshold to consider destination reached
@export var yellow_paint_enable_motion: bool = false

@onready var ray_left: RayCast2D = $RayCastWallHitLeft
@onready var ray_right: RayCast2D = $RayCastWallHitRight

var direction := 1
var start_position: Vector2
var travel_distance := 0.0
var base_dir := 1  # Remember initial horizontal direction for bounded oscillation
var to_target := true  # For GO_TO_TARGET_RETURN_START mode
var _yellow_unlocked: bool = false

func _ready():
	# Convert to kinematic mode
	PhysicsServer2D.body_set_mode(get_rid(), PhysicsServer2D.BODY_MODE_KINEMATIC)
	start_position = global_position
	direction = 1 if start_direction == 0 else -1
	base_dir = direction

	var paintable := get_node("PlatformPaintable")
	if paintable is PlatformPaintable:
		paintable.yellow_painted.connect(_on_platform_painted_yellow)
		paintable.yellow_cleared.connect(_on_platform_yellow_cleared)
		if (paintable as PlatformPaintable).color == PaintColor.Colors.YELLOW:
			_yellow_unlocked = true

func _physics_process(delta):
	var motion := Vector2.ZERO

	# keep platform stationary until unlocked by yellow paint
	if yellow_paint_enable_motion and not _yellow_unlocked:
		return
			
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
			var displacement_x := global_position.x - start_position.x
			var signed_disp := displacement_x * base_dir
			# Go outward until reaching pixel_offset, then return to start (0), not past it
			if direction == base_dir and signed_disp >= pixel_offset:
				direction = -base_dir
			elif direction == -base_dir and signed_disp <= 0.0:
				direction = base_dir

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

		# Vertical fixed path: move up/down between start.y and start.y + base_dir * pixel_offset
		MovementMode.FIXED_PATH_VERTICAL:
			motion = Vector2(0, direction * speed * delta)
			global_position += motion
			var displacement_y := global_position.y - start_position.y
			var signed_disp_y := displacement_y * base_dir
			# For vertical, base_dir uses start_direction (Right=1, Left=-1) but we repurpose as Up=-1, Down=1
			# Interpret base_dir: if start_direction == 0 (Right), treat as Down for vertical; if Left, treat as Up
			# Map base_dir to vertical_base_dir
			var vertical_base_dir := 1 if (start_direction == 0) else -1
			if direction == vertical_base_dir and signed_disp_y >= pixel_offset:
				direction = -vertical_base_dir
			elif direction == -vertical_base_dir and signed_disp_y <= 0.0:
				direction = vertical_base_dir

		# Go to target, then return to start, looping regardless of where target is
		MovementMode.GO_TO_TARGET_RETURN_START:
			var dest: Vector2 = target_global if to_target else start_position
			var to_vec: Vector2 = dest - global_position
			var dist := to_vec.length()
			if dist <= reach_threshold:
				to_target = !to_target
			else:
				motion = to_vec.normalized() * speed * delta
				global_position += motion
	
func _on_platform_painted_yellow() -> void:
	_yellow_unlocked = true

func reset_yellow_motion() -> void:
	_on_platform_yellow_cleared()

func _on_platform_yellow_cleared() -> void:
	if not yellow_paint_enable_motion:
		return
	_yellow_unlocked = false
	global_position = start_position
	direction = 1 if start_direction == 0 else -1
	to_target = true
