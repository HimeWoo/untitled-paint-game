extends TileMapLayer

# Define the maximum ID you have created.
# If you have Default (0), Red (1), and Blue (2), your count is 3.
const TOTAL_COLORS = 5

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cycle_tile_color()

func cycle_tile_color():
	var mouse_pos = get_local_mouse_position()
	var map_coords = local_to_map(mouse_pos)
	
	# 1. Get the current data
	var tile_data = get_cell_tile_data(map_coords)
	if tile_data == null:
		return
		
	# 2. Check permission (Custom Data)
	if tile_data.get_custom_data("can_paint"):
		
		# Get the current ID (0 = default, 1 = red, 2 = blue, etc.)
		var current_alt_id = get_cell_alternative_tile(map_coords)
		var source_id = get_cell_source_id(map_coords)
		var atlas_coords = get_cell_atlas_coords(map_coords)
		
		# 3. Calculate the NEXT ID
		# (0 + 1) % 3 = 1
		# (1 + 1) % 3 = 2
		# (2 + 1) % 3 = 0  <- Wraps back to start!
		var next_alt_id = (current_alt_id + 1) % TOTAL_COLORS
		
		# 4. Apply the new ID
		set_cell(map_coords, source_id, atlas_coords, next_alt_id)
		print("Cycled tile at ", map_coords, " from ID ", current_alt_id, " to ", next_alt_id)

func get_tile_data_at_position(global_pos: Vector2, layer_name: String):
	var local_pos = to_local(global_pos)
	var map_coords = local_to_map(local_pos)
	
	# Get the TileData object (holds physics, navigation, and custom data)
	var tile_data = get_cell_tile_data(map_coords)
	
	if tile_data:
		# Return the specific custom data value we asked for
		return tile_data.get_custom_data(layer_name)
	
	# Default return if no tile exists (e.g., walking on air/void)
	return null
