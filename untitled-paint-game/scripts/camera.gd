class_name Camera
extends Camera2D

@export var zoom_speed: float = 1.0
var target_zoom: Vector2 = zoom


func _process(delta: float) -> void:
  if not (target_zoom - zoom).is_zero_approx():
    zoom = zoom.lerp(target_zoom, delta * zoom_speed)


