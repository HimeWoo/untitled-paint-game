class_name MeleeAttack
extends Area2D 

@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2(300, -200) 
@export var active_time: float = 0.2

var owner_body: Node2D
var hit_objects: Array = [] 

func _ready() -> void:
	monitoring = false 
	visible = false
	

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func start_attack(attacker: Node2D, facing_dir: int) -> void:
	owner_body = attacker
	hit_objects.clear()
	
	scale.x = facing_dir 
	visible = true
	monitoring = true
	await get_tree().create_timer(active_time).timeout
	queue_free()

func _hit(target: Node) -> void:

	if target == owner_body: 
		return
		

	if target in hit_objects:
		return
	

	hit_objects.append(target)

	if target.has_method("apply_damage"):

		var final_knockback = knockback_force
		final_knockback.x *= scale.x 
		
		target.apply_damage(damage, final_knockback)
		print("Hit ", target.name, " for ", damage)

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	# Sometimes enemies are Areas (like hitboxes), sometimes Bodies
	_hit(area)
