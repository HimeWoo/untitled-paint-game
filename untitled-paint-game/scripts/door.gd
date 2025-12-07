extends StaticBody2D

func open():
	#$AnimationPlayer.play("open")
	print("door opened")
	$CollisionShape2D.set_deferred("disabled", true)

func close():
	print("door closed")
	#$AnimationPlayer.play("close")
	$CollisionShape2D.set_deferred("disabled", false)
