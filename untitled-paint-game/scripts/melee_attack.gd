class_name MeleeAttack
extends Area2D  # CHANGED: Must be Area2D, not Node2D

@export var damage: int = 10
# Default knockback (Kick them up and away)
@export var knockback_force: Vector2 = Vector2(300, -200) 
@export var active_time: float = 0.2

var owner_body: Node2D
var hit_objects: Array = [] # Track who we already hit this swing

func _ready() -> void:
	# Ensure we don't hurt ourselves or start active before told to
	monitoring = false 
	visible = false
	
	# Connect signals safely
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func start_attack(attacker: Node2D, facing_dir: int) -> void:
	owner_body = attacker
	hit_objects.clear() # Reset hit list for new swing
	
	# 1. Visuals and Position
	scale.x = facing_dir # Flips the collision shape left/right
	visible = true
	
	# 2. Enable Collision
	monitoring = true
	
	# 3. Start Timer (Code-only approach, no node needed)
	await get_tree().create_timer(active_time).timeout
	
	# 4. Cleanup
	queue_free()

func _hit(target: Node) -> void:
	# 1. Don't hit the user
	if target == owner_body: 
		return
		
	# 2. Don't hit the same enemy twice in one swing
	if target in hit_objects:
		return
	
	# Add to list so we don't hit them again this swing
	hit_objects.append(target)

	if target.has_method("apply_damage"):
		# Calculate knockback direction based on the sword's scale
		# If scale.x is -1 (left), x force becomes negative
		var final_knockback = knockback_force
		final_knockback.x *= scale.x 
		
		target.apply_damage(damage, final_knockback)
		print("Hit ", target.name, " for ", damage)

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	# Sometimes enemies are Areas (like hitboxes), sometimes Bodies
	_hit(area)
