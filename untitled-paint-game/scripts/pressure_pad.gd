extends Node2D

@export var linked_door: StaticBody2D 

var bodies_on_pad: int = 0

func _ready():
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D or body is RigidBody2D or body is Pushbox:
		bodies_on_pad += 1
		_update_door_state()

func _on_body_exited(body):
	if body is CharacterBody2D or body is RigidBody2D or body is Pushbox:
		bodies_on_pad -= 1
		_update_door_state()

func _update_door_state():
	if linked_door != null:
		if bodies_on_pad > 0:
			$Sprite2D.frame = 1 
			linked_door.open()
		else:
			$Sprite2D.frame = 0 
			linked_door.close()
