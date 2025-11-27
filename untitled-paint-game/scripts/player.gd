extends CharacterBody2D

#@onready var sprite: Sprite2D = $Sprite2D
@export var projectile_scene: PackedScene = preload("res://scenes/PlayerProjectile.tscn")
@export var shoot_cooldown: float = 0.25
var can_shoot := true

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

@export var terrain_map: TileMapLayer

func _ready() -> void:
	jumps_left = 1
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

	if dir == Vector2.ZERO:
		dir = Vector2(facing_dir, 0) 
	return dir.normalized()

func _shoot_projectile() -> void:
	can_shoot = false
	var proj := projectile_scene.instantiate()
	get_parent().add_child(proj)
	var spawn_pos := _get_projectile_spawn_pos()
	proj.global_position = spawn_pos
	proj.setup(_get_aim_dir(), 5)
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
	
func _get_projectile_spawn_pos() -> Vector2:
	if not has_node("ProjectileSpawn"):
		return global_position
	var spawn: Marker2D = $ProjectileSpawn
	var local = spawn.position
	local.x = abs(local.x) * facing_dir
	return global_position + local

func _physics_process(delta: float) -> void:
	# 1. DEFINE CURRENT STATS (Reset to base values every frame)
	var current_speed = SPEED
	var current_jump_velocity = JUMP_VELOCITY
	var current_dash_speed = DASH_SPEED
	
	# 2. CHECK TERRAIN EFFECTS
	if terrain_map:
		# Check 5 pixels below feet to ensure we hit the floor
		var floor_pos = global_position + Vector2(0, 10)
		var tile_coords = terrain_map.local_to_map(terrain_map.to_local(floor_pos))
		var tile_data = terrain_map.get_cell_tile_data(tile_coords)
		
		if tile_data:
			# --- RED (Speed) ---
			var speed_mult = tile_data.get_custom_data("speed_modifier")
			# Check if it exists (!= 0) AND if it's actually changing something (!= 1)
			if speed_mult != 0.0 and speed_mult != 1.0:
				current_speed *= speed_mult
				print("EFFECT ACTIVE: Speed changed to ", current_speed, " (Multiplier: ", speed_mult, ")")
				
			# --- BLUE (Jump) ---
			var jump_mult = tile_data.get_custom_data("jump_modifier")
			if jump_mult != 0.0 and jump_mult != 1.0:
				current_jump_velocity *= jump_mult
				print("EFFECT ACTIVE: Jump Height changed to ", current_jump_velocity, " (Multiplier: ", jump_mult, ")")

			# --- YELLOW (Dash) ---
			var dash_mult = tile_data.get_custom_data("dash_modifier")
			if dash_mult != 0.0 and dash_mult != 1.0:
				current_dash_speed *= dash_mult
				print("EFFECT ACTIVE: Dash Speed changed to ", current_dash_speed, " (Multiplier: ", dash_mult, ")")
				
			 #--- GREEN (Launch Pad) ---
			var launch = tile_data.get_custom_data("launch_force")
			# Only launch if we are strictly on the floor
			if launch != 0.0 and is_on_floor():
				velocity.y = launch
				jumps_left = 1 
				print("EFFECT TRIGGERED: Launched with force ", launch)

	# ----------------------------------------------------
	
	var facing_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var facing_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var dir := int(facing_right) - int(facing_left)
	if dir != 0:
		facing_dir = dir
		sprite.flip_h = (facing_dir == -1)

	var selected_item = inventory.current_color()
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot_projectile()
	
	if selected_item != null:
		var current_paint_color = PaintColor.Colors.find_key(selected_item)
		if current_paint_color != last_paint_color:
			# print("Switched to: ", current_paint_color) # Commented out to reduce console noise
			last_paint_color = current_paint_color
	
	_update_animation()

	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta
	elif is_on_floor():
		jumps_left = 1 

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = current_jump_velocity
		elif jumps_left > 0:
			velocity.y = current_jump_velocity
			jumps_left -= 1
		else:
			pass

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and is_on_floor():
		dash_direction = facing_dir if facing_dir != 0 else 1
		start_dash()
	if Input.is_action_just_pressed("melee_attack"):
		perform_slash()

	if is_dashing:
		dash_timer -= delta
		# Using the MODIFIED variable
		horizontal_momentum = dash_direction * current_dash_speed 
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
			# Using the MODIFIED variable
			horizontal_momentum = move_toward(horizontal_momentum, direction * current_speed, accel * delta)
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
	var is_moving: bool = abs(velocity.x) > 5.0
	var target_anim := "walk" if is_moving else "idle"
	if sprite.animation != target_anim:
		sprite.play(target_anim)
