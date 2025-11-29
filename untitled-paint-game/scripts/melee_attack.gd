class_name MeleeAttack
extends Area2D 

@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2(300, -200) 
@export var active_time: float = 0.2

var _tilemap: TileMapLayer
var _selected_color: PaintColor.Colors


var owner_body: Node2D
var hit_objects: Array = [] 

func _ready() -> void:
	monitoring = false 
	visible = false
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func start_attack(attacker: Node2D, facing_dir: int, terrain: TileMapLayer, color: PaintColor.Colors) -> void:
	owner_body = attacker
	_tilemap = terrain
	_selected_color = color
	hit_objects.clear()
	
	scale.x = facing_dir 
	visible = true
	monitoring = true
	
	_paint_tiles_under_hitbox()
	
	await get_tree().create_timer(active_time).timeout
	queue_free()

func _hit(target: Node) -> void:
	if target == owner_body: 
		return
		
	if target in hit_objects:
		return
	
	hit_objects.append(target)
	if target.has_method("apply_damage"):
		var final_knockback = knockback_force
		final_knockback.x *= scale.x 
		
		target.apply_damage(damage, final_knockback)
		print("Hit ", target.name, " for ", damage)


func _paint_tiles_under_hitbox() -> void:
	if _tilemap == null:
		return
	var shape: CollisionShape2D = $CollisionShape2D
	if shape.shape is RectangleShape2D:
		var extents: Vector2 = shape.shape.extents * shape.global_scale.abs()
		var top_left = shape.global_position - extents
		var bottom_right = shape.global_position + extents
		var start = _tilemap.local_to_map(_tilemap.to_local(top_left))
		var end = _tilemap.local_to_map(_tilemap.to_local(bottom_right))
		var alt_id = _color_to_alt(_selected_color)
		for x in range(start.x, end.x + 1):
			for y in range(start.y, end.y + 1):
				var cell := Vector2i(x, y)
				var data = _tilemap.get_cell_tile_data(cell)
				if data and data.get_custom_data("can_paint"):
					if _selected_color == PaintColor.Colors.PURPLE and _tilemap.has_method("paint_purple"):
						_tilemap.paint_purple(cell)
					else:
						var src = _tilemap.get_cell_source_id(cell)
						var atlas = _tilemap.get_cell_atlas_coords(cell)
						_tilemap.set_cell(cell, src, atlas, alt_id)

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
	_hit(area)
