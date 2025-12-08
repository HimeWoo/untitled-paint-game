class_name MeleeAttack
extends Area2D 

@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2(100, 0) 
@export var active_time: float = 0.2

# Pushbox pull settings
@export_group("Pushbox Pull")
@export var pushbox_pull_horizontal: float = 400.0
@export var pushbox_pull_vertical: float = -300.0
@export var pushbox_check_radius: float = 50.0

var _tilemap: TileMapLayer
var _selected_color: PaintColor.Colors
var owner_body: Node2D
var hit_objects: Array = [] 
var _attack_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	monitoring = false 
	visible = false
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func start_attack(attacker: Node2D, attack_dir: Vector2, terrain: TileMapLayer, color: PaintColor.Colors) -> void:
	owner_body = attacker
	_attack_dir = attack_dir.normalized()
	if _attack_dir == Vector2.ZERO:
		_attack_dir = Vector2.RIGHT
	_tilemap = terrain
	_selected_color = color
	hit_objects.clear()
	
	scale.x = sign(_attack_dir.x) if abs(_attack_dir.x) > 0.0 else 1.0
	visible = true
	monitoring = true
	
	_paint_tiles_under_hitbox()  # This now handles paint consumption
	_check_pushbox_hits()  # Manual check for pushboxes
	_check_platform_hits()  # Check for platforms too
	
	await get_tree().create_timer(active_time).timeout
	queue_free()

func _check_pushbox_hits() -> void:
	# Manually check for pushboxes in range using physics query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Use our collision shape
	var shape_node: CollisionShape2D = $CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return
	
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var results = space_state.intersect_shape(query, 32)
	
	for result in results:
		var body = result["collider"]
		if body is Pushbox and body != owner_body:
			_pull_pushbox(body)

func _hit(target: Node) -> void:
	if target == owner_body: 
		return
		
	if target in hit_objects:
		return
	
	hit_objects.append(target)
	
	# Check if it's a Pushbox
	if target is Pushbox:
		_pull_pushbox(target)
		return
	
	if target.has_method("apply_damage"):
		var final_knockback = knockback_force
		if abs(_attack_dir.x) > 0.0:
			final_knockback.x *= sign(_attack_dir.x)
		elif abs(_attack_dir.y) > 0.0:
			final_knockback = Vector2(0, abs(knockback_force.x) * sign(_attack_dir.y))
		
		target.apply_damage(damage, final_knockback)
		print("Melee hit ", target.name, " for ", damage)

func _pull_pushbox(box: Pushbox) -> void:
	if box in hit_objects:
		return
	hit_objects.append(box)
	
	# Get direction from box to player (pull towards player)
	var pull_dir = (owner_body.global_position - box.global_position).normalized()
	
	# Create pull force with upward component for "jump" effect
	var pull_force = Vector2(
		pull_dir.x * pushbox_pull_horizontal,
		pushbox_pull_vertical  # Negative = upward
	)
	
	# Unfreeze and apply the pull
	box.freeze = false
	box.apply_central_impulse(pull_force)
	
	print("Pulled pushbox towards player with force: ", pull_force)

func _check_platform_hits() -> void:
	# Manually check for platforms using physics query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var shape_node: CollisionShape2D = $CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return
	
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collide_with_bodies = false
	query.collide_with_areas = true
	
	var results = space_state.intersect_shape(query, 32)
	var painted_platform := false
	
	for result in results:
		var area = result["collider"]
		if area is PlatformPaintable and area != owner_body:
			(area as PlatformPaintable).set_color(_selected_color)
			painted_platform = true
	
	# Use paint if we painted any platforms
	if painted_platform and owner_body.has_method("use_paint_from_attack"):
		owner_body.use_paint_from_attack()

func _paint_tiles_under_hitbox() -> void:
	if _tilemap == null:
		return
	var shape: CollisionShape2D = $CollisionShape2D
	var rect := shape.shape.get_rect()
	
	var top_left_global := shape.to_global(rect.position)
	var bottom_right_global := shape.to_global(rect.end)
	var map_coord_1 = _tilemap.local_to_map(_tilemap.to_local(top_left_global))
	var map_coord_2 = _tilemap.local_to_map(_tilemap.to_local(bottom_right_global))
	var x_min = min(map_coord_1.x, map_coord_2.x)
	var x_max = max(map_coord_1.x, map_coord_2.x)
	var y_min = min(map_coord_1.y, map_coord_2.y)
	var y_max = max(map_coord_1.y, map_coord_2.y)
	var alt_id = _color_to_alt(_selected_color)
	var painted_any := false
	
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			var cell := Vector2i(x, y)
			var data = _tilemap.get_cell_tile_data(cell)
			
			if data and data.get_custom_data("can_paint"):
				if _selected_color == PaintColor.Colors.PURPLE and _tilemap.has_method("paint_purple"):
					_tilemap.paint_purple(cell)
					painted_any = true
				else:
					var src = _tilemap.get_cell_source_id(cell)
					var atlas = _tilemap.get_cell_atlas_coords(cell)
					_tilemap.set_cell(cell, src, atlas, alt_id)
					painted_any = true
	
	# Only use paint if we actually painted something
	if painted_any and owner_body.has_method("use_paint_from_attack"):
		owner_body.use_paint_from_attack()

func _color_to_alt(color: PaintColor.Colors) -> int:
	match color:
		PaintColor.Colors.RED: return 1
		PaintColor.Colors.BLUE: return 2
		PaintColor.Colors.GREEN: return 3
		PaintColor.Colors.YELLOW: return 4
		PaintColor.Colors.ORANGE: return 5
		PaintColor.Colors.PURPLE: return 7
		_ : return 0  # default/no paint

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	# Sometimes enemies are Areas (like hitboxes), sometimes Bodies
	if area is PlatformPaintable:
		var plat := area as PlatformPaintable
		plat.set_color(_selected_color)
		# Use paint when successfully painting a platform
		if owner_body.has_method("use_paint_from_attack"):
			owner_body.use_paint_from_attack()
	_hit(area)
