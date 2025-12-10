class_name OrangeWave
extends Node2D

@export var speed: float = 120.0
@export var throw_distance: float = 200.0
@export var floor_check_distance: float = 8.0
@export var paint_radius_tiles: int = 3

var _dir: int = 1
var _terrain: TileMapLayer
var _start_pos: Vector2

func setup(start_pos: Vector2, dir: int, terrain: TileMapLayer) -> void:
	_start_pos = start_pos
	global_position = start_pos
	_dir = dir if dir != 0 else 1
	_terrain = terrain
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/charas/abilities/paint-orange_wave.png")
	sprite.centered = true
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if _terrain == null:
		queue_free()
		return

	if global_position.distance_to(_start_pos) >= throw_distance:
		queue_free()
		return

	var floor_pos := global_position + Vector2(0, floor_check_distance)
	var center_cell := _terrain.local_to_map(_terrain.to_local(floor_pos))
	var center_data := _terrain.get_cell_tile_data(center_cell)
	if center_data == null:
		queue_free()
		return

	# Paint tiles around the projectile in ORANGE
	for dx in range(-paint_radius_tiles, paint_radius_tiles + 1):
		var cell := center_cell + Vector2i(dx, 0)
		var data := _terrain.get_cell_tile_data(cell)
		if data and data.get_custom_data("can_paint"):
			var src := _terrain.get_cell_source_id(cell)
			var atlas := _terrain.get_cell_atlas_coords(cell)
			_terrain.set_cell(cell, src, atlas, 5)

	var tile_size := _terrain.tile_set.tile_size
	var ahead_pos := global_position + Vector2(_dir * float(tile_size.x), 0)
	var ahead_cell := _terrain.local_to_map(_terrain.to_local(ahead_pos))
	var ahead_data := _terrain.get_cell_tile_data(ahead_cell)
	if ahead_data != null and not ahead_data.get_custom_data("can_paint"):
		queue_free()
		return

	global_position.x += float(_dir) * speed * delta
