extends RigidBody2D

@export var initial_velocity: Vector2 = Vector2(400, -100)
@export var water_friction: float = 0.98
@export var max_speed: float = 500.0
@export var settle_threshold: float = 5.0
@export var buoyancy_force: float = 400.0 # upwards force applied to player

var has_settled: bool = false
var settled_timer: float = 0.0
var last_velocity: Vector2 = Vector2.ZERO
var check_timer: float = 0.0
var player_in_water: bool = false
var overlapping_bodies: Array = []

func _ready() -> void:
	# Configure as a dynamic physics body, based on a fluid sim example
	gravity_scale = 2.0  # Higher gravity for faster settling like real water
	linear_damp = 0.1    # Very low damping for fluid movement
	angular_damp = 5.0
	
	linear_velocity = initial_velocity
	
	# Enable continuous collision detection for better fluid behavior
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	
	# Make it bounce less and slide more (like water)
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.1  # Very low bounce
	physics_material_override.friction = 0.0  # Zero friction like in fluid sims
	
	mass = 0.05 # super light mass
	can_sleep = true
	
	# Connect signals for detecting player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	_check_player_interaction()
	
	if has_settled:
		# Even when settled, keep checking if we should flow downward
		check_timer += delta
		if check_timer > 0.5:
			check_timer = 0.0
			_try_flow_down()
		
		# Check if player disturbs settled water
		if player_in_water:
			# Unsettle if player is moving through
			has_settled = false
			freeze = false
			settled_timer = 0.0
			collision_mask = 1  # Re-enable collision detection
		return
	
	# Clamp maximum speed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	
	# Check if water has mostly stopped moving (inspired by fluid sim's sleeping)
	if linear_velocity.length() < settle_threshold:
		settled_timer += delta
		if settled_timer > 0.2:  # Faster settling like the repo
			_settle_in_place()
	else:
		settled_timer = 0.0
		sleeping = false  # Wake up if moving again
	
	# Apply slight friction to horizontal movement (simulate water drag)
	linear_velocity.x *= water_friction
	
	# Store velocity for flow direction
	last_velocity = linear_velocity

func _check_player_interaction() -> void:
	# Detect overlapping bodies
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = get_node("CollisionShape2D").shape
	params.transform = global_transform
	params.collision_mask = 1
	params.exclude = [self]
	
	var results := space_state.intersect_shape(params, 10)
	
	player_in_water = false
	for result in results:
		var body := result.collider as Node
		if body is CharacterBody2D:
			player_in_water = true
			# Apply buoyancy force to player
			if body.has_method("apply_buoyancy"):
				body.apply_buoyancy(buoyancy_force * get_physics_process_delta_time())
			
			# Water gets displaced by player movement
			if not has_settled:
				var push_force: Vector2 = body.velocity * 0.3
				apply_central_impulse(push_force * mass)

func _settle_in_place() -> void:
	has_settled = true
	
	sleeping = true
	
	# Convert to static body so other water can rest on it
	freeze = true
	collision_layer = 1  # Same as terrain
	collision_mask = 0   # Don't detect anything
	
	# Flatten the shape to act as a water surface
	var collision := get_node_or_null("CollisionShape2D")
	if collision and collision.shape:
		# Make it wider and flatter to act as a platform
		if collision.shape is CircleShape2D:
			var circle := collision.shape as CircleShape2D
			var rect := RectangleShape2D.new()
			rect.size = Vector2(circle.radius * 3, circle.radius * 0.5)
			collision.shape = rect
		elif collision.shape is RectangleShape2D:
			var rect := collision.shape as RectangleShape2D
			rect.size = Vector2(rect.size.x * 1.5, rect.size.y * 0.3)
	
	# Try to place water in tilemap at current position
	var tilemap := _find_tilemap()
	if tilemap:
		_place_water_in_tilemap(tilemap)

func _try_flow_down() -> void:
	# Check if there's space below to flow into
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 32))
	query.exclude = [self]
	
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		# Nothing below, unfreeze and let it fall
		has_settled = false
		freeze = false
		settled_timer = 0.0

func _find_tilemap() -> Node:
	var root := get_tree().current_scene
	if not root:
		return null
	
	# Look for TileMapLayer in the scene
	for child in root.get_children():
		if child is TileMapLayer or child is TileMap:
			return child
	
	return null

func _place_water_in_tilemap(tilemap: Node) -> void:
	if tilemap is TileMapLayer:
		var local_pos: Vector2 = tilemap.to_local(global_position)
		var tile_pos: Vector2i = tilemap.local_to_map(local_pos)
		
		# Check if this position is empty and fill it
		var current_tile: int = tilemap.get_cell_source_id(tile_pos)
		if current_tile == -1:
			# Place water tile
			tilemap.set_cell(tile_pos, 0, Vector2i(2, 0))
			
			# Change sprite to indicate settled water (optional)
			modulate = Color(0.5, 0.7, 1.0, 0.5)
	elif tilemap is TileMap:
		var local_pos: Vector2 = tilemap.to_local(global_position)
		var tile_pos: Vector2i = tilemap.local_to_map(local_pos)
		var current_tile: int = tilemap.get_cell_source_id(0, tile_pos)
		if current_tile == -1:
			tilemap.set_cell(0, tile_pos, 0, Vector2i(2, 0))
			modulate = Color(0.5, 0.7, 1.0, 0.5)

func _on_body_entered(body: Node) -> void:
	if not body in overlapping_bodies:
		overlapping_bodies.append(body)

func _on_body_exited(body: Node) -> void:
	var idx := overlapping_bodies.find(body)
	if idx != -1:
		overlapping_bodies.remove_at(idx)
