class_name PaintColor

enum Colors {
	NONE,
	RED,
	BLUE,
	YELLOW,
	GREEN,
	PURPLE,
	ORANGE,
	BLACK,
}


## Returns the mixture of the two given colors
static func mix_colors(color1: Colors, color2: Colors) -> Colors:
	if color1 == color2:
		return color1
	match color1:
		Colors.RED:
			match color2:
				Colors.BLUE:
					return Colors.PURPLE
				Colors.YELLOW:
					return Colors.ORANGE
		Colors.BLUE:
			match color2:
				Colors.RED:
					return Colors.PURPLE
				Colors.YELLOW:
					return Colors.GREEN
		Colors.YELLOW:
			match color2:
				Colors.RED:
					return Colors.ORANGE
				Colors.BLUE:
					return Colors.GREEN
	return Colors.BLACK


## Returns true if red, blue, or yellow
static func is_primary(color: PaintColor.Colors) -> bool:
	return color == PaintColor.Colors.RED or color == PaintColor.Colors.BLUE or color == PaintColor.Colors.YELLOW