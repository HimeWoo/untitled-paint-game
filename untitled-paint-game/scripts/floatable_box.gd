class_name FloatableBox
extends RigidBody2D

@export var float_force: float = -300.0
@export var floating: bool = false

func start_floating() -> void:
	floating = true
	gravity_scale = 0.1

func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	if floating:
		apply_central_force(Vector2(0, float_force))
