extends Area2D

@export var speed: float = 300.0
@export var damage: int = 10
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, dmg: int = damage) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _try_damage(target: Node) -> void:
	if target.has_method("apply_damage"):
		target.apply_damage(damage, Vector2.ZERO)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return  # ignore self-collision
	
	if body.is_in_group("enemy"):
		_try_damage(body)
		return
	
	queue_free()  # world or other stuff

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_detection"):
		return  # ignore detection zones

	var parent_node := area.get_parent()
	if parent_node and parent_node.is_in_group("enemy"):
		_try_damage(parent_node)
