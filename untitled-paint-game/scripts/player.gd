extends CharacterBody2D

@export var projectile_scene: PackedScene = preload("res://scenes/PlayerProjectile.tscn")
@export var shoot_cooldown: float = 0.25
var can_shoot := true

# ---------- MOVEMENT VARIABLES ----------
const SPEED = 135.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 275.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 1.5
const GROUND_ACCEL = 1000.0
const GROUND_DECEL = 1000.0
const AIR_ACCEL = 400.0
const AIR_DECEL = 100.0
const DASH_DECEL = 0.0
const DASH_DECEL_DURATION = 0.25

var jumps_left = 1
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 1.0
var dash_direction = 0
var horizontal_momentum = 0.0
var dash_decel_timer = 0.0
var last_jump_was_double := false
var is_carrying_dash_momentum := false  # New: tracks if we jumped out of dash

# ---------- MELEE ATTACK VARIABLES ---------
const ATTACK_COOLDOWN = 0.2
var is_attacking = false 
var can_attack = true
var inventory: Inventory = Inventory.new()
var selector: PaintSelector = PaintSelector.new()
var last_paint_color = null 

var facing_dir := 1
var teleport_cooldown_timer := 0.0
var default_speed_scale := 1.0

@export var attack_scene: PackedScene = preload("res://scenes/MeleeAttack.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var terrain_map: TileMapLayer

var last_frame_tile_coords: Vector2i = Vector2i(-999, -999)

func _ready() -> void:
	jumps_left = 1
	default_speed_scale = sprite.speed_scale
	#inventory.select_index(0)

# need to update this for new the paint queue controls
#
# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("inv_next"):
# 		queue.select_next(1)
# 	elif event.is_action_pressed("inv_prev"):
# 		queue.select_next(-1)
# 	elif event is InputEventKey and event.pressed:
# 		var key_event := event as InputEventKey
# 		var num := key_event.keycode - KEY_1 
		

		#if num >= 0: 
			#inventory.select_index(num)
			
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
# 		if num >= 0: 
# 			queue.select_index(num)


func _physics_process(delta: float) -> void:
	# 1. DEFINE CURRENT STATS (Reset to base values every frame)
	var current_speed = SPEED
	var current_jump_velocity = JUMP_VELOCITY
	var current_dash_speed = DASH_SPEED
	
	if teleport_cooldown_timer > 0:
		teleport_cooldown_timer -= delta
	# 2. CHECK TERRAIN EFFECTS
	if terrain_map:
		# Check 5 pixels below feet to ensure we hit the floor
		var floor_pos = global_position + Vector2(0, 12)
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
			# --- PURPLE (Teleport) ---
			var is_teleporter = tile_data.get_custom_data("is_teleporter")

			if is_teleporter and tile_coords != last_frame_tile_coords and teleport_cooldown_timer <= 0: 
				var target_pos = terrain_map.get_teleport_target(tile_coords)
				if target_pos != Vector2.ZERO:
					var world_target = terrain_map.to_global(target_pos)
					var tile_height = terrain_map.tile_set.tile_size.y
					world_target.y -= tile_height
					global_position = world_target

					teleport_cooldown_timer = 1.0
					var dest_coords = terrain_map.local_to_map(terrain_map.to_local(world_target))
					last_frame_tile_coords = dest_coords
					
					print("WOOSH! Teleported to ", world_target)
		last_frame_tile_coords = tile_coords
	# ----------------------------------------------------
	var facing_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var facing_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var dir := int(facing_right) - int(facing_left)
	if dir != 0:
		facing_dir = dir
		sprite.flip_h = (facing_dir == -1)

	# i think this section i commented out isn't necessary anymore

	#var selected_item = queue.current_color()
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot_projectile()
	
	#if selected_item != null:
		#var current_paint_color = PaintColor.Colors.find_key(selected_item)
		#if current_paint_color != last_paint_color:
			## print("Switched to: ", current_paint_color) # Commented out to reduce console noise
			#last_paint_color = current_paint_color
	
	_update_animation()

	# Don't apply gravity during dash or when on floor
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta
	elif is_on_floor():
		jumps_left = 1 
		last_jump_was_double = false

	var jumped_this_frame := false
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or is_dashing:
			jumped_this_frame = true
			# If jumping out of a dash, mark that we're carrying momentum
			if is_dashing:
				print("Perfmed Dash Jump")
				# print("Current momentum: ", horizontal_momentum)
				is_carrying_dash_momentum = true
				end_dash()  # End dash but keep the momentum
			velocity.y = current_jump_velocity
			last_jump_was_double = false
		elif jumps_left > 0:
			jumped_this_frame = true
			velocity.y = current_jump_velocity
			jumps_left -= 1
			last_jump_was_double = true
		else:
			pass
	# Smoother jump release - reduce velocity by 50% instead of instantly to 0
	elif Input.is_action_just_released("jump") and velocity.y < 0 and not last_jump_was_double:
		velocity.y *= 0.5

	# Dash only when on the ground
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and is_on_floor():
		var left := Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D)
		dash_direction = int(right) - int(left)
		if dash_direction == 0:
			dash_direction = sign(velocity.x) if velocity.x != 0 else 1
		print("Dash Direction: ", dash_direction)
		start_dash()
	if Input.is_action_just_pressed("melee_attack"):
		perform_slash()

	if is_dashing:
		horizontal_momentum = dash_direction * current_dash_speed 
	else:
		# Use consistent input checking - check both action and direct keys
		var left := Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D)
		var direction := int(right) - int(left)
		
		# DEBUG: Print state every frame when carrying momentum
		# if is_carrying_dash_momentum:
			# print("carrying=true, on_floor=", is_on_floor(), ", momentum=", horizontal_momentum)

		var accel := 0.0
		var decel := 0.0
		if is_on_floor():
			accel = GROUND_ACCEL
			decel = GROUND_DECEL
			# Reset momentum carry when landing (but not on the frame we jump!)
			if is_carrying_dash_momentum and not jumped_this_frame:
				# print("LANDED -> Clearing momentum carry flag")
				is_carrying_dash_momentum = false
		else:
			accel = AIR_ACCEL
			# If carrying dash momentum, use much slower deceleration
			if is_carrying_dash_momentum:
				decel = 50.0  # Much slower air decel when carrying dash momentum
			else:
				decel = AIR_DECEL
		if dash_decel_timer > 0.0:
			decel = DASH_DECEL

		if direction != 0:
			# When carrying dash momentum and moving faster than normal speed
			if is_carrying_dash_momentum and abs(horizontal_momentum) > current_speed:
				# print("DEBUG - Carrying: ", is_carrying_dash_momentum, " | Momentum: ", horizontal_momentum, " | Current Speed: ", current_speed, " | Direction: ", direction, " | Sign match: ", sign(direction) == sign(horizontal_momentum))
				# If moving in the same direction as momentum, maintain it perfectly
				if sign(direction) == sign(horizontal_momentum):
					# Don't change momentum at all - perfect preservation
					# print("✓ Preserving dash momentum: ", horizontal_momentum, " | Direction: ", direction)
					pass
				else:
					# Allow changing direction with normal air control
					# print("✗ Changing direction - momentum: ", horizontal_momentum)
					horizontal_momentum = move_toward(horizontal_momentum, direction * current_speed, accel * delta)
			else:
				# Normal acceleration when not carrying dash momentum or slower than normal
				# if is_carrying_dash_momentum:
					# print("⚠ Lost momentum preservation! Momentum: ", horizontal_momentum, " vs Speed: ", current_speed)
				horizontal_momentum = move_toward(horizontal_momentum, direction * current_speed, accel * delta)
		else:
			# Only apply deceleration when no direction is held
			horizontal_momentum = move_toward(horizontal_momentum, 0.0, decel * delta)

	velocity.x = horizontal_momentum
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if dash_decel_timer > 0.0:
		dash_decel_timer -= delta
	
	# ---------------- Paint Queue ----------------
	if Input.is_action_just_pressed("queue_next"):
		_action_queue_next()
	elif Input.is_action_just_pressed("queue_prev"):
		_action_queue_prev()
	
	if Input.is_action_just_pressed("queue_red"):
		_action_queue_color(PaintColor.Colors.RED)
	if Input.is_action_just_pressed("queue_blue"):
		_action_queue_color(PaintColor.Colors.BLUE)
	if Input.is_action_just_pressed("queue_yellow"):
		_action_queue_color(PaintColor.Colors.YELLOW)
	if Input.is_action_just_pressed("queue_confirm"):
		_action_queue_confirm()
	if Input.is_action_just_pressed("queue_clear"):
		_action_queue_clear()
	# ---------------------------------------------

	move_and_slide()

func start_dash():
	is_dashing = true
	dash_timer = DASH_TIME # Optional: Keep this if you want to track time for other things
	
	# 1. Play animation
	sprite.play("dash")
	
	# 2. Set the momentum (Use horizontal_momentum, NOT velocity.x directly)
	horizontal_momentum = DASH_SPEED * dash_direction
	
	# 3. Wait for animation to finish
	await sprite.animation_finished
	
	# 4. Cleanup
	end_dash()

func end_dash() -> void:
	is_dashing = false
	dash_decel_timer = DASH_DECEL_DURATION
	dash_cooldown_timer = DASH_COOLDOWN  # Set the cooldown here!

func perform_slash() -> void:
	if not can_attack:
		return

	var attack_dir := _get_attack_direction()
	if attack_dir == Vector2.ZERO:
		attack_dir = Vector2(facing_dir, 0)
	var attack_offset := attack_dir.normalized() * 15.0
	var attack_anim := "slash_side"
	if attack_dir.y < 0:
		attack_anim = "slash_up"
	elif attack_dir.y > 0:
		attack_anim = "slash_down"
	sprite.play(attack_anim)

	is_attacking = true
	can_attack = false
	var attack_instance = attack_scene.instantiate()
	attack_instance.position = attack_offset
	add_child(attack_instance)
	attack_instance.start_attack(self, attack_dir, terrain_map, selector.get_selection().color)
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	is_attacking = false
	can_attack = true


func _update_animation() -> void:
	if sprite == null:
		return
	if is_dashing:
		return
	sprite.flip_h = facing_dir < 0
	if is_attacking:
		return
	
	# Reset speed_scale when changing away from dash
	if sprite.animation == "dash" and not is_dashing:
		# Wait for dash animation to finish before switching
		if sprite.frame < sprite.sprite_frames.get_frame_count("dash") - 1:
			return
		sprite.speed_scale = default_speed_scale
	
	var is_moving: bool = abs(velocity.x) > 5.0
	var target_anim := "walk" if is_moving else "idle"
	if sprite.animation != target_anim:
		sprite.play(target_anim)


func _action_queue_next() -> void:
	selector.select_next()


func _action_queue_prev() -> void:
	selector.select_prev()


func _action_queue_color(color: PaintColor.Colors) -> void:
	# Amount of the color in inventory
	var total_amt: int = inventory.count(color)
	# Amount of the color used but not confirmed
	var used_amt: int = selector.get_colors_used().count(color)
	if used_amt < total_amt:
		selector.add_color(color)


func _action_queue_confirm() -> void:
	if PaintColor.is_primary(selector.get_selection().color):
		return
	else:
		var palette: Array[PaintColor.Colors] = selector.get_colors_used()
		if palette.is_empty():
			return
		for color in palette:
			inventory.remove_color(color)
		selector.mix_selected()


func _action_queue_clear() -> void:
	selector.clear_selection()


func _get_attack_direction() -> Vector2:
	if Input.is_action_pressed("look_up"):
		return Vector2.UP
	if Input.is_action_pressed("look_down"):
		return Vector2.DOWN
	return Vector2(facing_dir, 0)
