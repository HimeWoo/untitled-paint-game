extends StaticBody2D


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func open():
	sprite.play("open")
	print("door opened")
	$CollisionShape2D.set_deferred("disabled", true)

func close():
	print("door closed")
	sprite.play("close")
	$CollisionShape2D.set_deferred("disabled", false)
