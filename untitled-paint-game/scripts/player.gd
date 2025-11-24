extends CharacterBody2D

@export var projectile_scene: PackedScene = preload("res://scenes/PlayerProjectile.tscn")
@export var shoot_cooldown: float = 0.25
var can_shoot := true

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
var last_paint_color = null 

var facing_dir := 1

@export var attack_scene: PackedScene = preload("res://scenes/MeleeAttack.tscn")

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
			
func _get_aim_dir() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("aim_left"): dir.x -= 1
	if Input.is_action_pressed("aim_right"): dir.x += 1
	if Input.is_action_pressed("aim_up"): dir.y -= 1
	if Input.is_action_pressed("aim_down"): dir.y += 1

	# fallback to facing direction if no aim held
	if dir == Vector2.ZERO:
		dir = Vector2(facing_dir, 0)  # assuming you already track facing_dir
	return dir.normalized()

func _shoot_projectile() -> void:
	can_shoot = false

	var proj := projectile_scene.instantiate()
	get_parent().add_child(proj)

	var spawn_pos := global_position
	if has_node("ProjectileSpawn"):
		spawn_pos = $ProjectileSpawn.global_position

	proj.global_position = spawn_pos
	proj.setup(_get_aim_dir(), 5)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func _physics_process(delta: float) -> void:
	var facing_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var facing_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var dir := int(facing_right) - int(facing_left)
	if dir != 0:
		facing_dir = dir

	var selected_item = inventory.current_color()
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot_projectile()
	
	# Check if we actually have a color selected (not null)
	if selected_item != null:
		var current_paint_color = PaintColor.Colors.find_key(selected_item)
		
		if current_paint_color != last_paint_color:
			print("Switched to: ", current_paint_color)
			last_paint_color = current_paint_color
	# --------------------------

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

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
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
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
		var direction := int(right) - int(left)

		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

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
