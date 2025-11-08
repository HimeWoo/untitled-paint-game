extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 700.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

var jumps_left = 1
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 0

func _ready() -> void:
	jumps_left = 1

func _physics_process(delta: float) -> void:
	# Apply gravity unless dashing
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta
	elif is_on_floor():
		jumps_left = 1  # reset double jump when landing

	# Handle jump (Space/W/Enter)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1

	# Handle dash (Shift)
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
		dash_direction = int(right) - int(left)
		if dash_direction == 0:
			dash_direction = sign(velocity.x) if velocity.x != 0 else 1
		start_dash()

	if is_dashing:
		dash_timer -= delta
		velocity.y = 0 
		velocity.x = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			end_dash()
	else:
		# Normal movement
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
		var direction := int(right) - int(left)

		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Cooldown tick
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	move_and_slide()


func start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN


func end_dash() -> void:
	is_dashing = false
