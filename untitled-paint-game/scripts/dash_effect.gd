extends Sprite2D

@export var fade_duration: float = 0.3

func _ready() -> void:
	# starts off half-transparent
	modulate.a = 0.5
	
	# fades out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(queue_free)
