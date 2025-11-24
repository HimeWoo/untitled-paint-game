extends CharacterBody2D

# ---------- MOVEMENT VARIABLES ----------
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 700.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5
const GROUND_ACCEL = 2000.0
const GROUND_DECEL = 3000.0
const AIR_ACCEL = 1200.0
const AIR_DECEL = 300.0
const DASH_DECEL = 2000.0
const DASH_DECEL_DURATION = 0.25


var jumps_left = 1
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 0
var horizontal_momentum = 0.0
var dash_decel_timer = 0.0

# ---------- MELEE ATTACK VARIABLES ---------
const ATTACK_COOLDOWN = 0.4
var is_attacking = false 
var can_attack = true
var inventory: Inventory = Inventory.new()
var last_paint_color = null 

var facing_dir := 1

@export var attack_scene: PackedScene = preload("res://scenes/MeleeAttack.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	jumps_left = 1
	
	# --- ADDED FOR TESTING ---
	# We need items in the inventory to test keys 1, 2, and 3!
	# Assuming PaintColor.Colors has RED, BLUE, GREEN
	#inventory.add_color(PaintColor.Colors.RED)   # Key 1
	#inventory.add_color(PaintColor.Colors.BLUE)  # Key 2
	#inventory.add_color(PaintColor.Colors.GREEN) # Key 3
	
	inventory.select_index(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inv_next"):
		inventory.select_next(1)
	elif event.is_action_pressed("inv_prev"):
		inventory.select_next(-1)
	elif event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		var num := key_event.keycode - KEY_1 
		

		if num >= 0: 
			inventory.select_index(num)

func _physics_process(delta: float) -> void:
	var facing_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var facing_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var dir := int(facing_right) - int(facing_left)
	if dir != 0:
		facing_dir = dir

	var selected_item = inventory.current_color()
	
	# Check if we actually have a color selected (not null)
	if selected_item != null:
		var current_paint_color = PaintColor.Colors.find_key(selected_item)
		
		if current_paint_color != last_paint_color:
			print("Switched to: ", current_paint_color)
			last_paint_color = current_paint_color
	# --------------------------
	_update_animation()

	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta
	elif is_on_floor():
		jumps_left = 1 

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
		else:
			print("No jumps left/not on floor")
			pass

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and is_on_floor():
		dash_direction = facing_dir if facing_dir != 0 else 1
		start_dash()
	if Input.is_action_just_pressed("melee_attack"):
		perform_slash()

	if is_dashing:
		dash_timer -= delta
		# removed to allow jumping during dash
		# velocity.y = 0
		horizontal_momentum = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			end_dash()
	else:
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
		var direction := int(right) - int(left)

		var accel := 0.0
		var decel := 0.0
		if is_on_floor():
			accel = GROUND_ACCEL
			decel = GROUND_DECEL
		else:
			accel = AIR_ACCEL
			decel = AIR_DECEL
		if dash_decel_timer > 0.0:
			decel = DASH_DECEL

		if direction != 0:
			horizontal_momentum = move_toward(horizontal_momentum, direction * SPEED, accel * delta)
		else:
			horizontal_momentum = move_toward(horizontal_momentum, 0.0, decel * delta)

	velocity.x = horizontal_momentum
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if dash_decel_timer > 0.0:
		dash_decel_timer -= delta

	move_and_slide()

func start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN

func end_dash() -> void:
	is_dashing = false
	dash_decel_timer = DASH_DECEL_DURATION

func perform_slash() -> void:
	if not can_attack:
		return

	is_attacking = true
	can_attack = false
	
	var attack_instance = attack_scene.instantiate()
	
	attack_instance.position = Vector2(50 * facing_dir, 0) 
	
	add_child(attack_instance)
	
	attack_instance.start_attack(self, facing_dir)
	
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	is_attacking = false
	can_attack = true
	
func _update_animation() -> void:
	if sprite == null:
		return
	sprite.flip_h = facing_dir < 0

	# Change 0.1 to 1.0 or even 5.0 to prevent micro-movements from triggering 'walk'
	var is_moving: bool = abs(velocity.x) > 5.0
	
	var target_anim := "walk" if is_moving else "idle"
	
	# Add this print line! If your Output log goes crazy switching 
	# between idle/walk, you know this is the problem.
	if sprite.animation != target_anim:
		print("Switching animation to: ", target_anim) 
		sprite.play(target_anim)
