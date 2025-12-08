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

# PUSH FORCE
@export var push_force: float = 150.0
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
@export var invincibility_duration: float = 0.30
@export var invincible_flash_interval: float = 0.15

var is_invincible: bool = false
var invincible_timer: float = 0.0
var invincible_flash_accum: float = 0.0

# MOVEMENT – BASE
@export_group("Movement - Base")
@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var coyote_time: float = 0.15

var coyote_timer: float = 0.0

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

@export_group("Dash VFX")
@export var dash_ghost_scene: PackedScene = preload("res://scenes/dash-effect.tscn")
@export var dash_ghost_interval: float = 0.02

var dash_ghost_timer: float = 0.0

# MOVEMENT – ACCEL/DECEL
@export_group("Movement - Accel / Decel")
@export var ground_accel: float = 2000.0
@export var ground_decel: float = 3000.0
@export var air_accel: float = 1200.0
@export var air_decel: float = 300.0

# TERRAIN
@export_group("Terrain")
@export var terrain_map: TileMapLayer
@export var platform_layer_bit: int = 2
@export var foot_check_offset_y: float = 12.0

# CHECKPOINTS
@export_group("Checkpoint")
@export var enable_checkpoints: bool = true
@export var item_red_scene: PackedScene = preload("res://scenes/items/red_paint.tscn")
@export var item_blue_scene: PackedScene = preload("res://scenes/items/blue_paint.tscn")
@export var item_yellow_scene: PackedScene = preload("res://scenes/items/yellow_paint.tscn")
var _checkpoint_active: bool = false
var _checkpoint_pos: Vector2 = Vector2.ZERO
var _checkpoint_room: Area2D = null
var _checkpoint_inventory: Dictionary = {}
var _checkpoint_paint: Dictionary = {} # Vector2i -> int (alt id)
var _checkpoint_room_rect: Rect2 = Rect2()
var _checkpoint_items: Array = [] # [{pos:Vector2, color:int}]
var _checkpoint_platforms: Array = [] # [{path:String, alt:int}]
var _respawn_grace_timer: float = 0.0
var _last_checkpoint_time: float = -999.0

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

# SFX
@onready var sfx_walk: AudioStreamPlayer2D = $SFX/Walk
@onready var sfx_jump: AudioStreamPlayer2D = $SFX/Jump
@onready var sfx_dash: AudioStreamPlayer2D = $SFX/Dash
@onready var sfx_shoot: AudioStreamPlayer2D = $SFX/Shoot
@onready var sfx_melee: AudioStreamPlayer2D = $SFX/Melee
@onready var sfx_land: AudioStreamPlayer2D = $SFX/Land
@onready var sfx_damage: AudioStreamPlayer2D = $SFX/Damage 
@onready var sfx_death: AudioStreamPlayer2D = $SFX/Death
@onready var sfx_pickup_paint: AudioStreamPlayer2D = $SFX/Pickup

# MISC
var is_dying: bool = false 

# LIFECYCLE
func _ready() -> void:
	jumps_left = 1
	default_speed_scale = sprite.speed_scale
	current_hp = max_hp
	z_index = 1  


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	var prev_vy := velocity.y
	
	_update_invincibility(delta)
	_update_post_dash_contact_grace(delta)

	# If in a death/respawn phase, ignore inputs and movement
	if is_dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1. Initialize stats using the BASE export variables
	var current_speed := move_speed
	var current_jump_velocity := jump_velocity
	var current_dash_speed := dash_speed
	
	# 2. Get the MODIFIED stats from the function
	var modified_stats = _calculate_terrain_stats(delta, current_speed, current_jump_velocity, current_dash_speed)
	
	# 3. Extract the results
	current_speed = modified_stats["speed"]
	current_jump_velocity = modified_stats["jump"]
	current_dash_speed = modified_stats["dash"]

	# Facing + combat inputs
	_update_facing_from_input()
	_handle_combat_input()

	# Animation (state-based)
	_update_animation()

	# Vertical motion (gravity / jumping)
	# Now using the correctly modified current_jump_velocity
	_handle_jump_and_gravity(delta, current_jump_velocity)

	# Dash and horizontal movement
	# Now using the correctly modified dash/move speeds
	_handle_dash_input(delta, current_dash_speed)
	_handle_horizontal_movement(delta, current_speed)

	# Paint queue input
	_handle_paint_queue_input()
	
	move_and_slide()

	# SFX updates
	_update_walk_sfx()
	_update_landing_sfx(was_on_floor, prev_vy)

	track_pushboxes(delta)

	if _respawn_grace_timer <= 0.0:
		_check_tile_collisions()

	if _respawn_grace_timer <= 0.0:
		_check_tile_collisions()

func track_pushboxes(delta: float):
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is Pushbox:
			collider.sleeping = false
			var push_vector := -c.get_normal() * push_force
			collider.attempt_push(push_vector)
		elif collider is RigidBody2D:
			collider.sleeping = false
			collider.apply_impulse(-c.get_normal() * 200.0)

	if _respawn_grace_timer > 0.0:
		_respawn_grace_timer -= delta


# DAMAGE
func apply_damage(amount: int, knockback: Vector2) -> void:
	# Ignore damage if invincible
	if is_invincible:
		return

	# Play hurt sound once at the moment damage is applied
	if sfx_damage:
		sfx_damage.play()

	is_invincible = true
	invincible_timer = invincibility_duration
	invincible_flash_accum = 0.0

	current_hp -= amount

	# Apply knockback
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
	if _respawn_grace_timer > 0.0:
		_respawn_grace_timer -= delta
		

# TERRAIN EFFECTS
# Returns a Dictionary with keys: speed, jump, dash
func _calculate_terrain_stats(
	delta: float,
	in_speed: float,
	in_jump: float,
	in_dash: float
) -> Dictionary:
	
	# Create local copies to modify
	var out_speed = in_speed
	var out_jump = in_jump
	var out_dash = in_dash

	if teleport_cooldown_timer > 0.0:
		teleport_cooldown_timer -= delta

	var tile_data = null
	var tile_coords := Vector2i(-999, -999)
	if terrain_map != null:
		var floor_pos := global_position + Vector2(0, foot_check_offset_y)
		tile_coords = terrain_map.local_to_map(terrain_map.to_local(floor_pos))
		tile_data = terrain_map.get_cell_tile_data(tile_coords)

	if tile_data:
		# RED (Speed)
		var speed_mult: float = tile_data.get_custom_data("speed_modifier")
		if speed_mult != 0.0 and speed_mult != 1.0:
			out_speed *= speed_mult

		# BLUE (Jump)
		var jump_mult: float = tile_data.get_custom_data("jump_modifier")
		if jump_mult != 0.0 and jump_mult != 1.0:
			out_jump *= jump_mult

		# YELLOW (Dash)
		var dash_mult: float = tile_data.get_custom_data("dash_modifier")
		if dash_mult != 0.0 and dash_mult != 1.0:
			out_dash *= dash_mult

		# GREEN (Launch Pad) - Directly modifies velocity, this is fine to keep as side effect
		var launch = tile_data.get_custom_data("launch_force")
		if launch != 0.0 and is_on_floor():
			velocity.y = launch
			jumps_left = 1

		# PURPLE (Teleport) - Side effect logic is fine here too
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
	else:
		# Only check platforms when not on a tile (player can't be on both)
		var platform_mods := _platform_modifiers_under_foot()
		out_speed *= platform_mods["speed_modifier"]
		out_jump *= platform_mods["jump_modifier"]
		out_dash *= platform_mods["dash_modifier"]

		# Platform GREEN launch pad effect
		var launch_force: float = 0.0
		if platform_mods.has("launch_force"):
			launch_force = float(platform_mods["launch_force"])
		if launch_force != 0.0 and is_on_floor():
			velocity.y = launch_force
			jumps_left = 1
	
	last_frame_tile_coords = tile_coords
	
	# RETURN the calculated values instead of overwriting the class variables
	return {"speed": out_speed, "jump": out_jump, "dash": out_dash}

func _platform_modifiers_under_foot() -> Dictionary:
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	var sp := PhysicsShapeQueryParameters2D.new()
	sp.shape = shape
	sp.transform = Transform2D(0.0, global_position + Vector2(0, foot_check_offset_y))
	sp.collide_with_areas = true
	sp.collide_with_bodies = false
	var hits := get_world_2d().direct_space_state.intersect_shape(sp, 8)
	for h in hits:
		var a = h.get("collider")
		if a is PlatformPaintable:
			return (a as PlatformPaintable).get_modifiers()
	return {"speed_modifier": 1.0, "jump_modifier": 1.0, "dash_modifier": 1.0, "launch_force": 0.0}

# INPUT HELPERS
func _update_facing_from_input() -> void:
	var facing_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var facing_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	var dir := int(facing_right) - int(facing_left)
	if dir != 0 and not is_attacking:
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
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = 1
		last_jump_was_double = false
	else:
		coyote_timer -= delta
	
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta

	var jumped_this_frame := false
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or is_dashing or coyote_timer > 0.0:
			jumped_this_frame = true
			if is_dashing:
				end_dash()
			velocity.y = current_jump_velocity
			last_jump_was_double = false
			coyote_timer = 0.0
		elif jumps_left > 0:
			jumped_this_frame = true
			velocity.y = current_jump_velocity
			jumps_left -= 1
			last_jump_was_double = true
	elif Input.is_action_just_released("jump") and velocity.y < 0 and not last_jump_was_double:
		velocity.y *= 0.5

	# PLAY JUMP SFX HERE
	if jumped_this_frame and sfx_jump:
		sfx_jump.play()


func _handle_dash_input(delta: float, current_dash_speed: float) -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and is_on_floor():
		var left := Input.is_action_pressed("move_left")
		var right := Input.is_action_pressed("move_right")
		dash_direction = int(right) - int(left)
		# if dash direction 0 use facing dir not fixed
		if dash_direction == 0:
			dash_direction = facing_dir
		# print("Dash Direction: ", dash_direction)
		start_dash()

	if is_dashing:
		horizontal_momentum = dash_direction * current_dash_speed
		
		dash_ghost_timer -= delta
		if dash_ghost_timer <= 0.0:
			_spawn_dash_ghost()
			dash_ghost_timer = dash_ghost_interval

func _spawn_dash_ghost() -> void:
	if dash_ghost_scene == null:
		return
		
	var ghost: Sprite2D = dash_ghost_scene.instantiate()
	get_parent().add_child(ghost)
	
	# Copy player's appearance
	ghost.global_position = sprite.global_position
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.scale

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

	if sfx_dash:
		sfx_dash.play()

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
	
	if sfx_melee:
		sfx_melee.play()

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

	
	# jump frames
	if not is_on_floor():
		if velocity.y < 0:
			if sprite.animation != "jump":
				sprite.play("jump")
			sprite.frame = 0
		else:
			if sprite.animation != "jump":
				sprite.play("jump")
			sprite.frame = 1 
		return
	
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
	# Check if we have any of this color left in inventory
	if inventory.has_color(color):
		# Remove from inventory when picking it up
		inventory.remove_color(color)
		selector.add_color(color)


func _action_queue_confirm() -> void:
	var selected = selector.get_selection()
	
	# Can't confirm primary colors or empty slots
	if selected.is_blank() or PaintColor.is_primary(selected.color):
		return

	# Confirm the mix - this locks it and frees inventory space
	selector.mix_selected()


func use_paint_from_attack() -> void:
	selector.use_selected_paint()


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
	return n != null and (n.is_in_group("hazard") or n.is_in_group("water"))

func _check_hazard_contact_and_die() -> void:
	if is_dying or _respawn_grace_timer > 0.0:
		return
	# 1) Any slide collisions with hazard bodies?
	for i in range(get_slide_collision_count()):
		var c: KinematicCollision2D = get_slide_collision(i)
		var col = c.get_collider()
		if col is Node and _is_hazard_node(col):
			print("Hazard contact (body): ", col.name)
			_die()
			return
#
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
	if is_dying:
		return
	is_dying = true

	if sfx_death:
		sfx_death.play()

	print("Player died: hazard contact")

	if enable_checkpoints and _checkpoint_active:
		_restore_checkpoint()
	else:
		is_dying = false
		get_tree().reload_current_scene()


func _check_tile_collisions() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider == terrain_map:
			var hit_pos = collision.get_position() - collision.get_normal()
			var tile_coords = terrain_map.local_to_map(terrain_map.to_local(hit_pos))
			
			var tile_data = terrain_map.get_cell_tile_data(tile_coords)
			if tile_data:
				var is_spike = tile_data.get_custom_data("is_spike")
				if is_spike: 
					_die()

# # Called by room transitions to register a checkpoint
func set_room_checkpoint(spawn_pos: Vector2, room_area: Area2D) -> void:
	if not enable_checkpoints:
		return
	if not can_set_checkpoint():
		print("[Checkpoint] Ignored set: grace timer active")
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_checkpoint_time < 0.75:
		print("[Checkpoint] Ignored set: cooldown")
		return
	_checkpoint_active = true
	_checkpoint_pos = spawn_pos
	_checkpoint_room = room_area
	_checkpoint_room_rect = _room_rect_or_fallback(room_area, spawn_pos)
	_checkpoint_inventory = _snapshot_inventory()
	_checkpoint_paint = _snapshot_room_paint_rect(_checkpoint_room_rect)
	_checkpoint_items = _snapshot_room_items(_checkpoint_room_rect)
	_checkpoint_platforms = _snapshot_room_platforms(_checkpoint_room_rect)
	_last_checkpoint_time = now

func _restore_checkpoint() -> void:
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	horizontal_momentum = 0.0
	is_attacking = false
	last_jump_was_double = false
	_restore_inventory(_checkpoint_inventory)
	if terrain_map != null:
		_restore_room_paint_rect(_checkpoint_room_rect, _checkpoint_paint)
	_restore_room_items(_checkpoint_room_rect, _checkpoint_items)
	_restore_room_platforms(_checkpoint_platforms)
	# Teleport to checkpoint
	global_position = _checkpoint_pos
	_respawn_grace_timer = 1.0
	is_dying = false
	await get_tree().process_frame
	if UISignals != null:
		UISignals.inventory_changed.emit(inventory)

func can_set_checkpoint() -> bool:
	return _respawn_grace_timer <= 0.0

func _snapshot_inventory() -> Dictionary:
	var snap: Dictionary = {}
	if inventory == null:
		return snap
	if inventory._contents is Dictionary:
		for color in inventory._contents.keys():
			snap[color] = int(inventory._contents[color])
	return snap

func _restore_inventory(snap: Dictionary) -> void:
	if inventory == null:
		return
	inventory.clear()
	for color in snap.keys():
		var count: int = int(snap[color])
		for i in range(count):
			inventory.add_color(color)

func _snapshot_room_items(rect: Rect2) -> Array:
	var items: Array = []
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return items
	var nodes: Array = scene_root.find_children("*", "WorldItem", true, false)
	for n in nodes:
		var pos := (n as Node2D).global_position
		if rect.has_point(pos):
			var wi := n as WorldItem
			var data := wi.data
			if data != null:
				var area := n as Area2D
				var parent_path: String = n.get_parent().get_path()
				items.append({
					"pos": pos,
					"color": int(data.color),
					"layer": int(area.collision_layer),
					"mask": int(area.collision_mask),
					"z": int((n as Node2D).z_index),
					"parent": parent_path
				})
	return items

func _restore_room_items(rect: Rect2, items: Array) -> void:
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return
	var existing: Array = scene_root.find_children("*", "WorldItem", true, false)
	for n in existing:
		var pos := (n as Node2D).global_position
		if rect.has_point(pos):
			(n as WorldItem).queue_free()
	# Respawn from snapshot
	for item in items:
		var pos: Vector2 = item["pos"]
		var color: int = item["color"]
		var scene: PackedScene = null
		if color == PaintColor.Colors.RED:
			scene = item_red_scene
		elif color == PaintColor.Colors.BLUE:
			scene = item_blue_scene
		elif color == PaintColor.Colors.YELLOW:
			scene = item_yellow_scene
		if scene != null:
			var inst = scene.instantiate()
			var parent_node: Node = scene_root
			if item.has("parent"):
				var p := scene_root.get_node_or_null(item["parent"])
				if p != null:
					parent_node = p
			parent_node.add_child(inst)
			(inst as Node2D).global_position = pos
			if item.has("z"):
				(inst as Node2D).z_index = int(item["z"])
			var area := inst as Area2D
			if area != null:
				if item.has("layer"):
					area.collision_layer = int(item["layer"])
				if item.has("mask"):
					area.collision_mask = int(item["mask"])

func _snapshot_room_paint_rect(rect: Rect2) -> Dictionary:
	var snap: Dictionary = {}
	if terrain_map == null:
		return snap
	for cell: Vector2i in terrain_map.get_used_cells():
		var cell_pos_local := terrain_map.map_to_local(cell)
		var cell_pos_global := terrain_map.to_global(cell_pos_local)
		if rect.has_point(cell_pos_global):
			var alt := terrain_map.get_cell_alternative_tile(cell)
			snap[cell] = alt
	return snap

func _snapshot_room_platforms(rect: Rect2) -> Array:
	var arr: Array = []
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return arr
	var nodes: Array = scene_root.find_children("*", "PlatformPaintable", true, false)
	for n in nodes:
		var p := n as Node2D
		if rect.has_point(p.global_position):
			arr.append({"path": str(n.get_path()), "alt": int((n as PlatformPaintable).get_color_alt())})
	return arr

func _restore_room_paint_rect(rect: Rect2, snap: Dictionary) -> void:
	if terrain_map == null:
		return
	for cell: Vector2i in terrain_map.get_used_cells():
		var cell_pos_local := terrain_map.map_to_local(cell)
		var cell_pos_global := terrain_map.to_global(cell_pos_local)
		if rect.has_point(cell_pos_global):
			var tile_data := terrain_map.get_cell_tile_data(cell)
			if tile_data and tile_data.get_custom_data("can_paint"):
				var src := terrain_map.get_cell_source_id(cell)
				var atlas := terrain_map.get_cell_atlas_coords(cell)
				var alt := 0
				if snap.has(cell):
					alt = int(snap[cell])
				terrain_map.set_cell(cell, src, atlas, alt)

func _restore_room_platforms(items: Array) -> void:
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return
	for it in items:
		var path: String = it["path"]
		var alt: int = it["alt"]
		var node := scene_root.get_node_or_null(path)
		if node is PlatformPaintable:
				(node as PlatformPaintable).set_color_alt(alt)

func _room_rect_global(area: Area2D) -> Rect2:
	var shape_node: CollisionShape2D = area.get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is RectangleShape2D:
		var size: Vector2 = (shape_node.shape as RectangleShape2D).size
		var center_global := shape_node.global_position
		var top_left := center_global - size * 0.5
		return Rect2(top_left, size)
	return Rect2(area.global_position - Vector2(64, 64), Vector2(128, 128))

func _room_rect_or_fallback(area: Area2D, around_pos: Vector2) -> Rect2:
	if area != null and is_instance_valid(area):
		return _room_rect_global(area)
	# Fallback to a local rect around the spawn position
	return Rect2(around_pos - Vector2(512, 384), Vector2(1024, 768))

func _update_walk_sfx() -> void:
	if sfx_walk == null:
		return
	var is_walking = is_on_floor() and abs(velocity.x) > 3.0 and not is_dashing and not is_dying

	if is_walking:
		if not sfx_walk.playing:
			sfx_walk.play()
	else:
		if sfx_walk.playing:
			sfx_walk.stop()

func _update_landing_sfx(was_on_floor: bool, prev_vy: float) -> void:
	if sfx_land == null:
		return

	var now_on_floor := is_on_floor()
	var just_landed := (not was_on_floor) and now_on_floor
	var HARD_LAND_VY_THRESHOLD := 250.0
	var hard_enough := prev_vy > HARD_LAND_VY_THRESHOLD

	if just_landed and hard_enough and not is_dying:
		sfx_land.play()
		
func play_paint_pickup_sfx() -> void:
	if sfx_pickup_paint:
		sfx_pickup_paint.play()
