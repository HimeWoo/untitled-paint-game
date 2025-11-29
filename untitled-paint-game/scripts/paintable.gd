extends TileMapLayer


const TOTAL_COLORS = 8
var purple_cells: Array[Vector2i] = []


func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cycle_tile_color()


func cycle_tile_color():
	var mouse_pos = get_local_mouse_position()
	var map_coords = local_to_map(mouse_pos)
	
	var tile_data = get_cell_tile_data(map_coords)
	if tile_data == null:
		return
		
	if tile_data.get_custom_data("can_paint"):
		
		var current_alt_id = get_cell_alternative_tile(map_coords)
		var source_id = get_cell_source_id(map_coords)
		var atlas_coords = get_cell_atlas_coords(map_coords)
		
		var next_alt_id = (current_alt_id + 1) % TOTAL_COLORS
		
		set_cell(map_coords, source_id, atlas_coords, next_alt_id)
		print("Cycled tile at ", map_coords, " from ID ", current_alt_id, " to ", next_alt_id)


func get_tile_data_at_position(global_pos: Vector2, layer_name: String):
	var local_pos = to_local(global_pos)
	var map_coords = local_to_map(local_pos)
	
	var tile_data = get_cell_tile_data(map_coords)
	
	if tile_data:
		return tile_data.get_custom_data(layer_name)
	
	return null


func get_teleport_target(current_coords: Vector2i) -> Vector2:
	var all_cells = get_used_cells()
	
	for cell_coords in all_cells:
		if cell_coords == current_coords:
			continue
			
		var tile_data = get_cell_tile_data(cell_coords)
		if tile_data and tile_data.get_custom_data("is_teleporter"):
			return map_to_local(cell_coords)
			
	return Vector2.ZERO


func paint_purple(cell: Vector2i) -> void:
	var alt_default := 0
	var alt_purple := 7
	if get_cell_alternative_tile(cell) == alt_purple:
		return

	if purple_cells.size() >= 2:
		var to_clear : Variant = purple_cells.pop_front()
		var src := get_cell_source_id(to_clear)
		var atlas := get_cell_atlas_coords(to_clear)
		set_cell(to_clear, src, atlas, alt_default)

	var src_new := get_cell_source_id(cell)
	var atlas_new := get_cell_atlas_coords(cell)
	set_cell(cell, src_new, atlas_new, alt_purple)
	purple_cells.push_back(cell)
