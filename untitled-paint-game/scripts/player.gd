extends CharacterBody2D

# ---------- MOVEMENT VARIABLES ----------
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

# ---------- MELEE ATTACK VARIABLES ---------
const ATTACK_COOLDOWN = 0.4
var is_attacking = false 
var can_attack = true
var inventory: Inventory = Inventory.new()
var paint_queue: PaintQueue = PaintQueue.new()
var last_paint_color = null 

var facing_dir := 1

@export var attack_scene: PackedScene = preload("res://scenes/MeleeAttack.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	jumps_left = 1

# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("inv_next"):
# 		queue.select_next(1)
# 	elif event.is_action_pressed("inv_prev"):
# 		queue.select_next(-1)
# 	elif event is InputEventKey and event.pressed:
# 		var key_event := event as InputEventKey
# 		var num := key_event.keycode - KEY_1 
		

# 		if num >= 0: 
# 			queue.select_index(num)

func _physics_process(delta: float) -> void:
	var facing_left := Input.is_action_pressed("move_left")
	var facing_right := Input.is_action_pressed("move_right")
	var dir := int(facing_right) - int(facing_left)
	if dir != 0:
		facing_dir = dir

	var selected_item = queue.current_color()
	
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

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		var left := Input.is_action_pressed("move_left")
		var right := Input.is_action_pressed("move_right")
		dash_direction = int(right) - int(left)
		if dash_direction == 0:
			dash_direction = sign(velocity.x) if velocity.x != 0 else 1
		start_dash()
	if Input.is_action_just_pressed("melee_attack"):
		perform_slash()

	if is_dashing:
		dash_timer -= delta
		velocity.y = 0 
		velocity.x = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			end_dash()
	else:
		var left := Input.is_action_pressed("move_left")
		var right := Input.is_action_pressed("move_right")
		var direction := int(right) - int(left)

		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# ---------------- Paint Queue ----------------
	if Input.is_action_just_pressed("queue_next"):
		paint_queue.selected_index = wrapi(paint_queue.selected_index + 1, 0, paint_queue.get_capacity())
	elif Input.is_action_just_pressed("queue_prev"):
		paint_queue.selected_index = wrapi(paint_queue.selected_index - 1, 0, paint_queue.get_capacity())
	
	if Input.is_action_just_pressed("queue_red"):
		if inventory.has_color(PaintColor.Colors.RED):
			paint_queue.add_color(PaintColor.Colors.RED)
	if Input.is_action_just_pressed("queue_blue"):
		if inventory.has_color(PaintColor.Colors.BLUE):
			paint_queue.add_color(PaintColor.Colors.BLUE)
	if Input.is_action_just_pressed("queue_yellow"):
		if inventory.has_color(PaintColor.Colors.YELLOW):
			paint_queue.add_color(PaintColor.Colors.YELLOW)
	if Input.is_action_just_pressed("queue_clear"):
		paint_queue.clear()
	# ---------------------------------------------

	move_and_slide()

func start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN

func end_dash() -> void:
	is_dashing = false

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


func _action_select_red():
	if inventory.has_color(PaintColor.Colors.RED):
		paint_queue.add_color(PaintColor.Colors.RED)


func _action_select_blue():
	if inventory.has_color(PaintColor.Colors.BLUE):
		paint_queue.add_color(PaintColor.Colors.BLUE)


func _action_select_yellow():
	if inventory.has_color(PaintColor.Colors.YELLOW):
		paint_queue.add_color(PaintColor.Colors.YELLOW)