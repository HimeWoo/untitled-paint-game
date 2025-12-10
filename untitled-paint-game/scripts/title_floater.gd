extends Sprite2D

@export var amplitude: float = 8.0  
@export var speed: float = 2.0 

var base_y: float

func _ready():
	base_y = position.y

func _process(delta):
	position.y = base_y + sin(Time.get_ticks_msec() / 1000.0 * speed) * amplitude
