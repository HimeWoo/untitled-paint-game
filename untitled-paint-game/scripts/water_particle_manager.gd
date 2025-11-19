extends Node2D
## High-performance water particle system using Physics2DServer
## Based on Chevifier's fluid simulation approach

@export var particle_texture: Texture2D
@export var max_water_particles: int = 2000
@export var particle_radius: float = 8.0
@export var particle_color: Color = Color(0.3, 0.6, 1.0, 0.8)

# Physics parameters (from Chevifier's fluid sim)
const PARTICLE_MASS: float = 0.05
const PARTICLE_FRICTION: float = 0.0
const PARTICLE_GRAVITY_SCALE: float = 2.0
const PARTICLE_BOUNCE: float = 0.1
const SLEEP_THRESHOLD: float = 5.0

# Fluid cohesion/surface tension
const COHESION_DISTANCE: float = 32.0  # Distance particles attract
const COHESION_FORCE: float = 400.0    # Strength of attraction
const PRESSURE_FORCE: float = 600.0    # Push apart when too close
const BUOYANCY_FORCE_PER_PARTICLE: float = 200.0  # Upward force per overlapping particle

var water_particles: Array = []  # Array of [RID, RID] pairs (physics body, canvas item)
var particle_velocities: Array = []  # Track velocities for effects
var spawn_queue: Array = []  # Queue of particles to spawn
var player_body: RID = RID()  # Track player for buoyancy

func _ready() -> void:
	# Ensure we have a default texture if none provided
	if not particle_texture:
		_create_default_texture()
	
	# Find player for buoyancy calculations
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player and player is CharacterBody2D:
		player_body = player.get_rid()

func spawn_particle(pos: Vector2, velocity: Vector2) -> void:
	if water_particles.size() >= max_water_particles:
		return
	
	spawn_queue.append([pos, velocity])

func _physics_process(delta: float) -> void:
	# Spawn queued particles
	for spawn_data in spawn_queue:
		_create_particle(spawn_data[0], spawn_data[1])
	spawn_queue.clear()
	
	# Apply cohesion forces between particles
	_apply_cohesion_forces(delta)
	
	# Apply buoyancy to player if in water
	_apply_player_buoyancy(delta)
	
	# Update all particle visuals
	_update_particle_visuals()
	
	# Clean up particles that fall too far
	_cleanup_particles()

func _create_particle(pos: Vector2, velocity: Vector2) -> void:
	var ps := PhysicsServer2D
	var vs := RenderingServer
	
	# Create transform
	var trans := Transform2D()
	trans.origin = pos
	
	# === PHYSICS BODY ===
	var body: RID = ps.body_create()
	ps.body_set_mode(body, PhysicsServer2D.BODY_MODE_RIGID)
	ps.body_set_space(body, get_world_2d().space)
	
	# Create circle shape
	var shape: RID = ps.circle_shape_create()
	ps.shape_set_data(shape, particle_radius)
	ps.body_add_shape(body, shape, Transform2D.IDENTITY)
	
	# Collision layers
	ps.body_set_collision_layer(body, 2)  # Water layer
	ps.body_set_collision_mask(body, 1 | 2)  # Collide with terrain and water
	
	# Physics parameters (from Chevifier's approach)
	ps.body_set_param(body, PhysicsServer2D.BODY_PARAM_MASS, PARTICLE_MASS)
	ps.body_set_param(body, PhysicsServer2D.BODY_PARAM_FRICTION, PARTICLE_FRICTION)
	ps.body_set_param(body, PhysicsServer2D.BODY_PARAM_GRAVITY_SCALE, PARTICLE_GRAVITY_SCALE)
	ps.body_set_param(body, PhysicsServer2D.BODY_PARAM_BOUNCE, PARTICLE_BOUNCE)
	ps.body_set_param(body, PhysicsServer2D.BODY_PARAM_LINEAR_DAMP, 0.1)
	ps.body_set_param(body, PhysicsServer2D.BODY_PARAM_ANGULAR_DAMP, 5.0)
	
	# Set initial state
	ps.body_set_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM, trans)
	ps.body_set_state(body, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, velocity)
	
	# === VISUAL (Canvas Item) ===
	var canvas_item := vs.canvas_item_create()
	vs.canvas_item_set_parent(canvas_item, get_canvas_item())
	vs.canvas_item_set_transform(canvas_item, trans)
	
	# Draw circle or texture
	if particle_texture:
		var rect := Rect2()
		rect.position = Vector2(-particle_radius, -particle_radius)
		rect.size = Vector2(particle_radius * 2, particle_radius * 2)
		vs.canvas_item_add_texture_rect(canvas_item, rect, particle_texture.get_rid())
	else:
		# Draw a simple circle
		vs.canvas_item_add_circle(canvas_item, Vector2.ZERO, particle_radius, particle_color)
	
	# Add to tracking arrays
	water_particles.append([body, canvas_item])
	particle_velocities.append(velocity)

func _apply_cohesion_forces(delta: float) -> void:
	var ps := PhysicsServer2D
	var particle_count := water_particles.size()
	
	for i in range(particle_count):
		var pair_i: Array = water_particles[i]
		var body_i: RID = pair_i[0]
		var pos_i: Vector2 = ps.body_get_state(body_i, PhysicsServer2D.BODY_STATE_TRANSFORM).origin
		
		var cohesion_force := Vector2.ZERO
		var neighbor_count := 0
		
		# Check against other particles
		for j in range(particle_count):
			if i == j:
				continue
			
			var pair_j: Array = water_particles[j]
			var body_j: RID = pair_j[0]
			var pos_j: Vector2 = ps.body_get_state(body_j, PhysicsServer2D.BODY_STATE_TRANSFORM).origin
			
			var dist := pos_i.distance_to(pos_j)
			
			if dist < COHESION_DISTANCE and dist > 0:
				var dir := (pos_j - pos_i).normalized()
				
				# Too close? Push apart (pressure)
				if dist < particle_radius * 2.5:
					var pressure_strength := (1.0 - dist / (particle_radius * 2.5))
					cohesion_force -= dir * PRESSURE_FORCE * pressure_strength
				else:
					# Far enough? Pull together (cohesion)
					var cohesion_strength := 1.0 - (dist / COHESION_DISTANCE)
					cohesion_force += dir * COHESION_FORCE * cohesion_strength
				
				neighbor_count += 1
		
		# Apply force if we have neighbors
		if neighbor_count > 0:
			cohesion_force *= delta
			ps.body_apply_central_force(body_i, cohesion_force)

func _apply_player_buoyancy(delta: float) -> void:
	if not player_body.is_valid():
		return
	
	var ps := PhysicsServer2D
	var player := get_tree().current_scene.get_node_or_null("Player")
	if not player or not player is CharacterBody2D:
		return
	
	var player_pos: Vector2 = player.global_position
	var player_collision := player.get_node_or_null("CollisionShape2D")
	var player_size := Vector2(50, 50)  # Default size
	
	if player_collision and player_collision.shape is RectangleShape2D:
		player_size = (player_collision.shape as RectangleShape2D).size
	
	# Count particles overlapping player
	var overlapping_count := 0
	var water_push_force := Vector2.ZERO
	
	for pair in water_particles:
		var body: RID = pair[0]
		var particle_pos: Vector2 = ps.body_get_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM).origin
		
		# Check if particle overlaps player bounds
		var diff := particle_pos - player_pos
		if abs(diff.x) < (player_size.x * 0.5 + particle_radius) and \
		   abs(diff.y) < (player_size.y * 0.5 + particle_radius):
			overlapping_count += 1
			
			# Water pushes away from player (displacement)
			if diff.length() > 0:
				var push_dir := diff.normalized()
				var push_strength := 1.0 - (diff.length() / player_size.length())
				water_push_force = push_dir * 2000.0 * push_strength
				ps.body_apply_central_impulse(body, water_push_force * delta)
	
	# Apply buoyancy to player
	if overlapping_count > 0:
		var buoyancy := BUOYANCY_FORCE_PER_PARTICLE * overlapping_count
		player.apply_buoyancy(buoyancy)

func _update_particle_visuals() -> void:
	var ps := PhysicsServer2D
	var vs := RenderingServer
	
	for i in range(water_particles.size()):
		var pair: Array = water_particles[i]
		var body: RID = pair[0]
		var canvas_item: RID = pair[1]
		
		# Get current transform from physics
		var trans: Transform2D = ps.body_get_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM)
		
		# Update visual position (relative to this node)
		trans.origin = trans.origin - global_position
		vs.canvas_item_set_transform(canvas_item, trans)
		
		# Store velocity for potential use
		particle_velocities[i] = ps.body_get_state(body, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)

func _cleanup_particles() -> void:
	var ps := PhysicsServer2D
	var vs := RenderingServer
	
	var i := 0
	while i < water_particles.size():
		var pair: Array = water_particles[i]
		var body: RID = pair[0]
		var canvas_item: RID = pair[1]
		
		var trans: Transform2D = ps.body_get_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM)
		
		# Remove if fallen too far or moved too far from camera
		if trans.origin.y > 2000 or trans.origin.distance_to(global_position) > 3000:
			ps.free_rid(body)
			vs.free_rid(canvas_item)
			water_particles.remove_at(i)
			particle_velocities.remove_at(i)
		else:
			i += 1

func _create_default_texture() -> void:
	# Create a simple circular texture
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Draw a circle
	for x in range(32):
		for y in range(32):
			var dist := Vector2(x - 16, y - 16).length()
			if dist <= 15:
				var alpha := 1.0 - (dist / 15.0) * 0.3
				img.set_pixel(x, y, Color(0.3, 0.6, 1.0, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	particle_texture = ImageTexture.create_from_image(img)

func get_particle_count() -> int:
	return water_particles.size()

func clear_all_particles() -> void:
	var ps := PhysicsServer2D
	var vs := RenderingServer
	
	for pair in water_particles:
		ps.free_rid(pair[0])
		vs.free_rid(pair[1])
	
	water_particles.clear()
	particle_velocities.clear()

func _exit_tree() -> void:
	clear_all_particles()
