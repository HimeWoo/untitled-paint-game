extends TileMapLayer

## This script helps manage terrain interactions with water
## Attach this to your TileMapLayer node

@export var water_atlas_coords: Vector2i = Vector2i(2, 0)  # Coordinates of water tile in your tileset
@export var water_source_id: int = 0  # Source ID of your tileset

func fill_water_at_position(global_pos: Vector2) -> bool:
	var local_pos := to_local(global_pos)
	var tile_pos := local_to_map(local_pos)
	
	# Check if this cell is empty
	var current_tile := get_cell_source_id(tile_pos)
	if current_tile == -1:
		# Empty cell - fill it with water
		set_cell(tile_pos, water_source_id, water_atlas_coords)
		return true
	
	return false

func is_hole_at_position(global_pos: Vector2) -> bool:
	var local_pos := to_local(global_pos)
	var tile_pos := local_to_map(local_pos)
	var current_tile := get_cell_source_id(tile_pos)
	return current_tile == -1
