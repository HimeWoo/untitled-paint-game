extends CharacterBody2D

# COMBAT – RANGED
@export_group("Combat - Ranged")
@export var projectile_scene: PackedScene = preload("res://scenes/PlayerProjectile.tscn")
@export var shoot_cooldown: float = 0.25
@export var invincible_shoot_cooldown_mult: float = 2.5

# COMBAT – MELEE
@export_group("Combat - Melee")
@export var attack_scene: PackedScene = preload("res://scenes/MeleeAttack.tscn")
@export var attack_cooldown: float = 0.2
@export var melee_knockback_force: Vector2 = Vector2(300.0, -200.0)

# PLAYER STATS
@export_group("Player Stats")
@export var max_hp: int = 100

var current_hp: int
var can_shoot: bool = true
var is_attacking: bool = false
var can_attack: bool = true

var inventory: Inventory = Inventory.new()
var selector: PaintSelector = PaintSelector.new()
var last_paint_color = null
var facing_dir: int = 1

# INVINCIBILITY STAGE
@export_group("Invincibility")
@export var invincibility_duration: float = 1.2
@export var invincible_flash_interval: float = 0.15

var is_invincible: bool = false
var invincible_timer: float = 0.0
var invincible_flash_accum: float = 0.0

# MOVEMENT – BASE
@export_group("Movement - Base")
@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0

# MOVEMENT – DASH
@export_group("Movement - Dash")
@export var dash_speed: float = 500.0
@export var dash_time: float = 0.10
@export var dash_cooldown: float = 0.5
@export var dash_decel: float = 2000.0
@export var dash_decel_duration: float = 0.25

@export_group("Contact / Dash Grace")
@export var post_dash_contact_grace: float = 0.25

var post_dash_contact_timer: float = 0.0


# MOVEMENT – ACCEL/DECEL
@export_group("Movement - Accel / Decel")
@export var ground_accel: float = 2000.0
@export var ground_decel: float = 3000.0
@export var air_accel: float = 1200.0
@export var air_decel: float = 300.0

# TERRAIN
@export_group("Terrain")
@export var terrain_map: TileMapLayer
@export var foot_check_offset_y: float = 12.0

# RUNTIME MOVEMENT STATE
var jumps_left: int = 1
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 0
var horizontal_momentum: float = 0.0
var dash_decel_timer: float = 0.0
var last_jump_was_double: bool = false

var teleport_cooldown_timer: float = 0.0
var default_speed_scale: float = 1.0
var last_frame_tile_coords: Vector2i = Vector2i(-999, -999)

# NODES
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# LIFECYCLE
func _ready() -> void:
	jumps_left = 1
	default_speed_scale = sprite.speed_scale
	current_hp = max_hp
	z_index = 1  


func _physics_process(delta: float) -> void:
	_update_invincibility(delta)
	_update_post_dash_contact_grace(delta)

	# Movement stats (base + terrain modifiers)
	var current_speed := move_speed
	var current_jump_velocity := jump_velocity
	var current_dash_speed := dash_speed
	_apply_terrain_effects(delta, current_speed, current_jump_velocity, current_dash_speed)

	# Facing + combat inputs
	_update_facing_from_input()
	_handle_combat_input()

	# Animation (state-based)
	_update_animation()

	# Vertical motion (gravity / jumping)
	_handle_jump_and_gravity(delta, current_jump_velocity)

	# Dash and horizontal movement
	_handle_dash_input(current_dash_speed)
	_handle_horizontal_movement(delta, current_speed)

	# Paint queue input
	_handle_paint_queue_input()

	# Apply motion
	move_and_slide()


# DAMAGE
func apply_damage(amount: int, knockback: Vector2) -> void:
	if is_invincible:
		return
	is_invincible = true
	invincible_timer = invincibility_duration
	invincible_flash_accum = 0.0

	current_hp -= amount

	horizontal_momentum += knockback.x
	velocity.y += knockback.y

	print("Player took ", amount, " damage. HP = ", current_hp, "/", max_hp)

	if current_hp <= 0:
		_die()

# While dashing, ignore contact damage entirely
func apply_contact_damage(amount: int, knockback: Vector2) -> void:
	if is_dashing or post_dash_contact_timer > 0.0:
		return

	apply_damage(amount, knockback)

# INVINCIBILITY 
func _update_invincibility(delta: float) -> void:
	if is_invincible:
		invincible_timer -= delta
		invincible_flash_accum += delta

		if invincible_flash_accum >= invincible_flash_interval:
			invincible_flash_accum = 0.0
			if sprite.modulate == Color(1, 1, 1, 1):
				sprite.modulate = Color(0.893, 0.0, 0.085, 1.0)
			else:
				sprite.modulate = Color(1, 1, 1, 1)

		if invincible_timer <= 0.0:
			is_invincible = false
			sprite.modulate = Color(1, 1, 1, 1)
	else:
		sprite.modulate = Color(1, 1, 1, 1)

# POST DASH INVINCIBILITY 
func _update_post_dash_contact_grace(delta: float) -> void:
	if post_dash_contact_timer > 0.0:
		post_dash_contact_timer -= delta

# TERRAIN EFFECTS
func _apply_terrain_effects(
	delta: float,
	current_speed: float,
	current_jump_velocity: float,
	current_dash_speed: float
) -> void:
	if teleport_cooldown_timer > 0.0:
		teleport_cooldown_timer -= delta

	if terrain_map == null:
		return

	var floor_pos := global_position + Vector2(0, foot_check_offset_y)
	var tile_coords := terrain_map.local_to_map(terrain_map.to_local(floor_pos))
	var tile_data := terrain_map.get_cell_tile_data(tile_coords)

	if tile_data:
		# RED (Speed)
		var speed_mult: float = tile_data.get_custom_data("speed_modifier")
		if speed_mult != 0.0 and speed_mult != 1.0:
			current_speed *= speed_mult
			print("EFFECT ACTIVE: Speed changed to ", current_speed, " (Multiplier: ", speed_mult, ")")

		# BLUE (Jump)
		var jump_mult: float = tile_data.get_custom_data("jump_modifier")
		if jump_mult != 0.0 and jump_mult != 1.0:
			current_jump_velocity *= jump_mult
			print("EFFECT ACTIVE: Jump Height changed to ", current_jump_velocity, " (Multiplier: ", jump_mult, ")")

		# YELLOW (Dash)
		var dash_mult: float = tile_data.get_custom_data("dash_modifier")
		if dash_mult != 0.0 and dash_mult != 1.0:
			current_dash_speed *= dash_mult
			print("EFFECT ACTIVE: Dash Speed changed to ", current_dash_speed, " (Multiplier: ", dash_mult, ")")

		# GREEN (Launch Pad)
		var launch = tile_data.get_custom_data("launch_force")
		if launch != 0.0 and is_on_floor():
			velocity.y = launch
			jumps_left = 1
			print("EFFECT TRIGGERED: Launched with force ", launch)

		# PURPLE (Teleport)
		var is_teleporter: bool = tile_data.get_custom_data("is_teleporter")
		if is_teleporter and tile_coords != last_frame_tile_coords and teleport_cooldown_timer <= 0.0:
			var target_pos = terrain_map.get_teleport_target(tile_coords)
			if target_pos != Vector2.ZERO:
				var world_target := terrain_map.to_global(target_pos)
				var tile_height := terrain_map.tile_set.tile_size.y
				world_target.y -= tile_height
				global_position = world_target

				teleport_cooldown_timer = 1.0
				var dest_coords := terrain_map.local_to_map(terrain_map.to_local(world_target))
				last_frame_tile_coords = dest_coords

				print("WOOSH! Teleported to ", world_target)

	last_frame_tile_coords = tile_coords
	move_speed = current_speed
	jump_velocity = current_jump_velocity
	dash_speed = current_dash_speed

# INPUT HELPERS
func _update_facing_from_input() -> void:
	var facing_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var facing_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var dir := int(facing_right) - int(facing_left)

	if dir != 0:
		facing_dir = dir
		sprite.flip_h = (facing_dir == -1)


func _handle_combat_input() -> void:
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot_projectile()

	if Input.is_action_just_pressed("melee_attack"):
		perform_slash()


func _handle_paint_queue_input() -> void:
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

# JUMP / GRAVITY / MOVE
func _handle_jump_and_gravity(delta: float, current_jump_velocity: float) -> void:
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
				# is_carrying_dash_momentum = true
				end_dash()  # End dash but keep the momentum
			velocity.y = current_jump_velocity
			last_jump_was_double = false
		elif jumps_left > 0:
			jumped_this_frame = true
			velocity.y = current_jump_velocity
			jumps_left -= 1
			last_jump_was_double = true
	elif Input.is_action_just_released("jump") and velocity.y < 0 and not last_jump_was_double:
		velocity.y *= 0.5


func _handle_dash_input(current_dash_speed: float) -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		var left := Input.is_action_pressed("move_left")
		var right := Input.is_action_pressed("move_right")
		dash_direction = int(right) - int(left)
		if dash_direction == 0:
			dash_direction = sign(velocity.x) if velocity.x != 0 else 1
		print("Dash Direction: ", dash_direction)
		start_dash()

	if is_dashing:
		horizontal_momentum = dash_direction * current_dash_speed


func _handle_horizontal_movement(delta: float, current_speed: float) -> void:
	if not is_dashing:
		var left := Input.is_action_pressed("move_left")
		var right := Input.is_action_pressed("move_right")
		var direction := int(right) - int(left)
		
		# DEBUG: Print state every frame when carrying momentum
		# if is_carrying_dash_momentum:
			# print("carrying=true, on_floor=", is_on_floor(), ", momentum=", horizontal_momentum)

		var accel := 0.0
		var decel := 0.0
		if is_on_floor():
			accel = ground_accel
			decel = ground_decel
		else:
			accel = air_accel
			decel = air_decel

		if dash_decel_timer > 0.0:
			decel = dash_decel

		if direction != 0:
			horizontal_momentum = move_toward(horizontal_momentum, direction * current_speed, accel * delta)
		else:
			# Only apply deceleration when no direction is held
			horizontal_momentum = move_toward(horizontal_momentum, 0.0, decel * delta)

	velocity.x = horizontal_momentum

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if dash_decel_timer > 0.0:
		dash_decel_timer -= delta


	# After movement, check overlaps/collisions with hazards (nodes in groups: hazard/water/spike)
	_check_hazard_contact_and_die()

func start_dash():
	is_dashing = true
	dash_timer = dash_time

	sprite.play("dash")

	horizontal_momentum = dash_speed * dash_direction

	await sprite.animation_finished
	end_dash()


func end_dash() -> void:
	is_dashing = false
	dash_decel_timer = dash_decel_duration
	post_dash_contact_timer = post_dash_contact_grace


# COMBAT: MELEE
func perform_slash() -> void:
	# Do not allow melee while invincible or on cooldown
	if not can_attack or is_invincible:
		return

	var attack_dir := _get_attack_direction()
	if attack_dir == Vector2.ZERO:
		attack_dir = Vector2(facing_dir, 0)

	var attack_offset := attack_dir.normalized() * 15.0
	var attack_anim := "slash_side"
	if attack_dir.y < 0.0:
		attack_anim = "slash_up"
	elif attack_dir.y > 0.0:
		attack_anim = "slash_down"
	sprite.play(attack_anim)

	is_attacking = true
	can_attack = false

	var attack_instance := attack_scene.instantiate()
	attack_instance.position = attack_offset
	add_child(attack_instance)

	attack_instance.knockback_force = melee_knockback_force
	attack_instance.start_attack(self, attack_dir, terrain_map, selector.get_selection().color)

	await get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false
	can_attack = true


# COMBAT: RANGED
func _get_aim_dir() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("aim_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("aim_right"):
		dir.x += 1.0
	if Input.is_action_pressed("aim_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("aim_down"):
		dir.y += 1.0

	if dir == Vector2.ZERO:
		dir = Vector2(facing_dir, 0.0)
	return dir.normalized()


func _shoot_projectile() -> void:
	can_shoot = false

	var proj := projectile_scene.instantiate()
	get_parent().add_child(proj)
	var spawn_pos := _get_projectile_spawn_pos()
	proj.global_position = spawn_pos
	proj.setup(_get_aim_dir(), 5)

	var cooldown_mult := invincible_shoot_cooldown_mult if is_invincible else 1.0
	var effective_cd := shoot_cooldown * cooldown_mult

	await get_tree().create_timer(effective_cd).timeout
	can_shoot = true


func _get_projectile_spawn_pos() -> Vector2:
	if not has_node("ProjectileSpawn"):
		return global_position
	var spawn: Marker2D = $ProjectileSpawn
	var local := spawn.position
	local.x = abs(local.x) * facing_dir
	return global_position + local


# ANIMATION
func _update_animation() -> void:
	if sprite == null:
		return
	if is_dashing:
		return
	if is_attacking:
		return

	sprite.flip_h = facing_dir < 0

	# Reset speed_scale when changing away from dash
	if sprite.animation == "dash" and not is_dashing:
		if sprite.frame < sprite.sprite_frames.get_frame_count("dash") - 1:
			return
		sprite.speed_scale = default_speed_scale

	var is_moving: bool = abs(velocity.x) > 5.0
	var target_anim := "walk" if is_moving else "idle"
	if sprite.animation != target_anim:
		sprite.play(target_anim)


# PAINT QUEUE HELPERS
func _action_queue_next() -> void:
	selector.select_next()


func _action_queue_prev() -> void:
	selector.select_prev()


func _action_queue_color(color: PaintColor.Colors) -> void:
	var total_amt: int = inventory.count(color)
	var used_amt: int = selector.get_colors_used().count(color)
	if used_amt < total_amt:
		selector.add_color(color)


func _action_queue_confirm() -> void:
	if PaintColor.is_primary(selector.get_selection().color):
		return

	var palette: Array[PaintColor.Colors] = selector.get_colors_used()
	if palette.is_empty():
		return

	for color in palette:
		inventory.remove_color(color)
	selector.mix_selected()


func _action_queue_clear() -> void:
	selector.clear_selection()


# ATTACK DIRECTION
func _get_attack_direction() -> Vector2:
	if Input.is_action_pressed("look_up"):
		return Vector2.UP
	if Input.is_action_pressed("look_down"):
		return Vector2.DOWN
	return Vector2(facing_dir, 0)
	
# --- Hazard helpers ---
func _is_hazard_node(n: Node) -> bool:
	return n != null and (n.is_in_group("hazard") or n.is_in_group("water") or n.is_in_group("spike"))

func _check_hazard_contact_and_die() -> void:
	# 1) Any slide collisions with hazard bodies?
	for i in range(get_slide_collision_count()):
		var c: KinematicCollision2D = get_slide_collision(i)
		var col = c.get_collider()
		if col is Node and _is_hazard_node(col):
			print("Hazard contact (body): ", col.name)
			_die()
			return

	# 2) Overlapping hazard Areas using a small shape around the player (more reliable than point)
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	var sp := PhysicsShapeQueryParameters2D.new()
	sp.shape = shape
	sp.transform = Transform2D(0.0, global_position)
	sp.collide_with_areas = true
	sp.collide_with_bodies = false
	var ahits := get_world_2d().direct_space_state.intersect_shape(sp, 16)
	for h in ahits:
		var a = h.get("collider")
		if a is Node and _is_hazard_node(a):
			print("Hazard contact (area): ", a.name)
			_die()
			return

func _die() -> void:
	print("Player died: hazard contact")
	get_tree().reload_current_scene()
