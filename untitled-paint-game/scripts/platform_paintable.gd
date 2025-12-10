class_name PlatformPaintable
extends Area2D

signal yellow_painted

@export var color: PaintColor.Colors = PaintColor.Colors.NONE
@export var sprite_path: NodePath
@export var launch_force: float = -600.0

@export var colors: Array[Color] = [
	Color(1,1,1,1), # NONE
	Color(1,0,0,1), # RED
	Color(0,0,1,1), # BLUE
	Color(1.825, 1.825, 0.0), # YELLOW
	Color(0,1,0,1), # GREEN
	Color(0.6,0,0.6,1), # PURPLE
	Color(1,0.5,0,1)  # ORANGE
]

var _alt_id: int = 0

func _ready() -> void:
	add_to_group("platform_paintable")
	_apply_color()

func set_color_alt(id: int) -> void:
	var prev_color := color
	_alt_id = clamp(id, 0, colors.size() - 1)
	color = _alt_to_enum(_alt_id)
	_apply_color()
	_check_yellow_paint_trigger(prev_color)

func set_color(p_color: PaintColor.Colors) -> void:
	var prev_color := color
	color = p_color
	_alt_id = _enum_to_alt(p_color)
	_apply_color()
	_check_yellow_paint_trigger(prev_color)

func get_color_alt() -> int:
	return _alt_id

func _apply_color() -> void:
	# Platform structure is known: tint the parent Sprite2D directly
	var tint := colors[_alt_id]
	var parent := get_parent()
	if parent != null:
		var sprite := parent.get_node_or_null("Sprite2D")
		if sprite is CanvasItem:
			(sprite as CanvasItem).modulate = tint

func _alt_to_enum(id: int) -> PaintColor.Colors:
	match id:
		0: return PaintColor.Colors.NONE
		1: return PaintColor.Colors.RED
		2: return PaintColor.Colors.BLUE
		3: return PaintColor.Colors.YELLOW
		4: return PaintColor.Colors.GREEN
		5: return PaintColor.Colors.PURPLE
		6: return PaintColor.Colors.ORANGE
	return PaintColor.Colors.NONE

func _enum_to_alt(c: PaintColor.Colors) -> int:
	match c:
		PaintColor.Colors.NONE: return 0
		PaintColor.Colors.RED: return 1
		PaintColor.Colors.BLUE: return 2
		PaintColor.Colors.YELLOW: return 3
		PaintColor.Colors.GREEN: return 4
		PaintColor.Colors.PURPLE: return 5
		PaintColor.Colors.ORANGE: return 6
	return 0

func _check_yellow_paint_trigger(prev_color: PaintColor.Colors) -> void:
	if prev_color == PaintColor.Colors.YELLOW:
		return
	if color == PaintColor.Colors.YELLOW:
		print("Yellow color")
		yellow_painted.emit()

func get_modifiers() -> Dictionary:
	# Mirror tile paint effects: RED=speed, BLUE=jump, YELLOW=dash
	var speed_mult := 1.0
	var jump_mult := 1.0
	var dash_mult := 1.0
	var launch := 0.0
	match color:
		PaintColor.Colors.RED:
			speed_mult = 1.3
		PaintColor.Colors.BLUE:
			jump_mult = 1.3
		PaintColor.Colors.YELLOW:
			dash_mult = 1.3
		PaintColor.Colors.GREEN:
			# Mixed color: small boost to all
			speed_mult = 1.15
			jump_mult = 1.15
			dash_mult = 1.15
			launch = launch_force
		PaintColor.Colors.PURPLE:
			# Example: slight jump + dash
			jump_mult = 1.2
			dash_mult = 1.2
		PaintColor.Colors.ORANGE:
			# Example: speed + dash
			speed_mult = 1.2
			dash_mult = 1.2
		PaintColor.Colors.NONE:
			pass
	return {"speed_modifier": speed_mult, "jump_modifier": jump_mult, "dash_modifier": dash_mult, "launch_force": launch}
