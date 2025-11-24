class_name PaintColor

enum Colors {
	NONE,
	RED,
	BLUE,
	YELLOW,
	GREEN,
	PURPLE,
	ORANGE,
	BROWN,
	BLACK,
}


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