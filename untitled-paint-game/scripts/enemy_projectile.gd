extends Area2D

@export var speed: float = 350.0
@export var damage: int = 5
@export var lifetime: float = 3.0
@export var homing_strength: float = 0.0  # 0 = straight shot

var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, tgt: Node2D = null, dmg: int = damage, homing: float = homing_strength) -> void:
	velocity = dir.normalized() * speed
	target = tgt
	damage = dmg
	homing_strength = homing
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if target and homing_strength > 0.0 and is_instance_valid(target):
		var desired := (target.global_position - global_position).normalized() * speed
		velocity = velocity.lerp(desired, homing_strength * delta)
		rotation = velocity.angle()

	global_position += velocity * delta

func _hit_player(p: Node) -> void:
	if p.has_method("apply_damage"):
		p.apply_damage(damage, Vector2.ZERO)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_hit_player(body)
	else:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent_node := area.get_parent()
	if parent_node and parent_node.is_in_group("player"):
		_hit_player(parent_node)
