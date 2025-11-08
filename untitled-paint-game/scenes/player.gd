extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Determine movement direction (supports arrows and WASD)
	var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var direction := int(right) - int(left)

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
