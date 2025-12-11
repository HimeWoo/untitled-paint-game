class_name PlayerCheckpoint
extends Node

# For future users who come upon this script:
# This script should be attached as a child node of the Player node in the scene tree.
# This code is a helper that owns all checkpoint/respawn state and logic for the Player.
# There were issues around paint pickups disappearing on respawn, so this code was ultimately
# not used. This code is identical to what is currently in Player.gd itself, but needs some 
# changes to work as a separate component.
# There are also issues with the PushBoxes, while they do reset their position, their
# sprites do not move away from the start position UNTIL you reach the point where they
# were when you died.
# The issue with paint is NOT there when this code is in Player.gd directly, but the PushBox
# issue is still there.
# For the future, make sure to set player checkpoint positions for rooms, since not using it
# might be the reason the paint pickup and pushbox issues are there.
# This was also written with only 1-2 features in mind, and then expanded upon, so is 
# definitely messy and could be optimized or cleaned up but I do not have the time for it right now.

@onready var player = get_parent()

# CHECKPOINTS
@export_group("Checkpoint")
@export var enable_checkpoints: bool = true
@export var item_red_scene: PackedScene = preload("res://scenes/items/red_paint.tscn")
@export var item_blue_scene: PackedScene = preload("res://scenes/items/blue_paint.tscn")
@export var item_yellow_scene: PackedScene = preload("res://scenes/items/yellow_paint.tscn")
var checkpoint_active: bool = false
var checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_room: Area2D = null
var checkpoint_inventory: Dictionary = {}
var checkpoint_paint: Dictionary = {}
var checkpoint_room_rect: Rect2 = Rect2()
var checkpoint_items: Array = []
var checkpoint_platforms: Array = []
var checkpoint_selector: Dictionary = {}
var respawn_grace_timer: float = 0.0
var last_checkpoint_time: float = -999.0

# set a new checkpoint
func set_room_checkpoint(spawn_pos: Vector2, room_area: Area2D) -> void:
	if not enable_checkpoints:
		return
	if not can_set_checkpoint():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_checkpoint_time < 0.75:
		return
	checkpoint_active = true
	checkpoint_pos = spawn_pos
	checkpoint_room = room_area
	print("Room Area: ", room_area)
	checkpoint_room_rect = room_rect_or_fallback(room_area, spawn_pos)
	checkpoint_inventory = snapshot_inventory()
	checkpoint_paint = snapshot_room_paint_rect(checkpoint_room_rect)
	checkpoint_items = snapshot_room_items(checkpoint_room_rect)
	checkpoint_platforms = snapshot_room_platforms(checkpoint_room_rect)
	if player.selector != null:
		checkpoint_selector = player.selector.snapshot()
	last_checkpoint_time = now

# restore the player and world state back to the last checkpoint
func restore_checkpoint() -> void:
	player.velocity = Vector2.ZERO
	player.is_dashing = false
	player.dash_timer = 0.0
	player.dash_cooldown_timer = 0.0
	player.horizontal_momentum = 0.0
	player.is_attacking = false
	player.last_jump_was_double = false
	
	# Reset health on respawn
	player.current_hp = player.max_hp
	if UISignals:
		UISignals.player_hp_changed.emit(player.current_hp, player.max_hp)
	
	restore_inventory(checkpoint_inventory)
	if player.terrain_map != null:
		restore_room_paint_rect(checkpoint_room_rect, checkpoint_paint)
	restore_room_items(checkpoint_room_rect, checkpoint_items)
	restore_room_platforms(checkpoint_platforms)
	reset_all_pushboxes_to_start()
	if player.selector != null and not checkpoint_selector.is_empty():
		player.selector.restore(checkpoint_selector)
	
	# tp to checkpoint
	player.global_position = checkpoint_pos
	respawn_grace_timer = 1.0
	player.is_dying = false
	await get_tree().process_frame
	if UISignals != null:
		UISignals.inventory_changed.emit(player.inventory)

# return true if the player is allowed to set a new checkpoint.
func can_set_checkpoint() -> bool:
	return respawn_grace_timer <= 0.0

# take a snapshot of the player inventory
func snapshot_inventory() -> Dictionary:
	var snap: Dictionary = {}
	if player.inventory == null:
		return snap
	if player.inventory._contents is Dictionary:
		for color in player.inventory._contents.keys():
			snap[color] = int(player.inventory._contents[color])
	return snap

# restore the player inventory
func restore_inventory(snap: Dictionary) -> void:
	if player.inventory == null:
		return
	player.inventory.clear()
	for color in snap.keys():
		var count: int = int(snap[color])
		for i in range(count):
			player.inventory.add_color(color)

# Capture all WorldItem nodes inside a rectangular region.
# Does not seem to properly work when not in player.gd
func snapshot_room_items(rect: Rect2) -> Array:
	var items: Array = []
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return items
	var nodes: Array = scene_root.find_children("*", "WorldItem", true, false)
	print("Found ", nodes.size(), " WorldItem nodes for snapshot")
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

# Clear and respawn WorldItem nodes in a region based on a snapshot.
func restore_room_items(rect: Rect2, items: Array) -> void:
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

# Record alternative tile indices for paintable tiles inside a region.
func snapshot_room_paint_rect(rect: Rect2) -> Dictionary:
	var snap: Dictionary = {}
	if player.terrain_map == null:
		return snap
	for cell: Vector2i in player.terrain_map.get_used_cells():
		var cell_pos_local: Vector2 = player.terrain_map.map_to_local(cell)
		var cell_pos_global: Vector2 = player.terrain_map.to_global(cell_pos_local)
		if rect.has_point(cell_pos_global):
			var alt: int = player.terrain_map.get_cell_alternative_tile(cell)
			snap[cell] = alt
	return snap

# Snapshot all paintable platforms (by path and alt) inside a region.
func snapshot_room_platforms(rect: Rect2) -> Array:
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

# Restore paint on tiles inside a region from the snapshot dict
func restore_room_paint_rect(rect: Rect2, snap: Dictionary) -> void:
	if player.terrain_map == null:
		return
	for cell: Vector2i in player.terrain_map.get_used_cells():
		var cell_pos_local: Vector2 = player.terrain_map.map_to_local(cell)
		var cell_pos_global: Vector2 = player.terrain_map.to_global(cell_pos_local)
		if rect.has_point(cell_pos_global):
			var tile_data: TileData = player.terrain_map.get_cell_tile_data(cell)
			if tile_data and tile_data.get_custom_data("can_paint"):
				var src:int = player.terrain_map.get_cell_source_id(cell)
				var atlas:Vector2i = player.terrain_map.get_cell_atlas_coords(cell)
				var alt := 0
				if snap.has(cell):
					alt = int(snap[cell])
				player.terrain_map.set_cell(cell, src, atlas, alt)

# Restore original platform paint state and reset yellow-activated motion platforms if needed
func restore_room_platforms(items: Array) -> void:
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return
	for item in items:
		var path: String = item["path"]
		var orig_alt: int = item["alt"]
		var alt: int = orig_alt
		var node := scene_root.get_node_or_null(path)
		if orig_alt == 3:
			alt = 0
		if node is PlatformPaintable:
			if orig_alt == 3:
				var parent := node.get_parent()
				if parent != null and parent.has_method("reset_yellow_motion"):
					parent.reset_yellow_motion()
			(node as PlatformPaintable).set_color_alt(alt)

# Reset all Pushbox nodes back to their start positions
func reset_all_pushboxes_to_start() -> void:
	var scene_root := get_tree().get_current_scene()
	if scene_root == null:
		return
	var nodes: Array = scene_root.find_children("*", "Pushbox", true, false)
	for n in nodes:
		if n is Pushbox:
			(n as Pushbox).reset_to_start()

# Compute a global Rect2 for a rectangular Area2D, used for room bounds.
func room_rect_global(area: Area2D) -> Rect2:
	print("Room Rect Global")
	var shape_node: CollisionShape2D = area.get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is RectangleShape2D:
		var size: Vector2 = (shape_node.shape as RectangleShape2D).size
		var center_global := shape_node.global_position
		var top_left := center_global - size * 0.5
		print("Top Left: ", top_left, " Size: ", size)
		return Rect2(top_left, size)
	print("Area has no rectangular shape, using fallback rect")
	return Rect2(area.global_position - Vector2(64, 64), Vector2(128, 128))

# Return the room rect if the Area2D is valid, otherwise a fallback around a point.
func room_rect_or_fallback(area: Area2D, around_pos: Vector2) -> Rect2:
	print("Area: ", area)
	if area != null and is_instance_valid(area):
		return room_rect_global(area)
	print("Invalid room area, using the fallback")
	return Rect2(around_pos - Vector2(700, 400), Vector2(1024, 768))
