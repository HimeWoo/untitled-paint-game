extends CharacterBody2D
class_name Enemy

@export var stats: EnemyStats
@export var projectile_scene: PackedScene

var hp: int

var player: Node2D = null
var base_y: float
var t: float = 0.0
var patrol_dir: int = -1
var can_fire: bool = true
var facing_dir: int = -1

@onready var detection_area: Area2D = $DetectionArea
@onready var fire_timer: Timer = $FireTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var contact_area: Area2D = $ContactDamageArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var sfx_damage: AudioStreamPlayer2D = $SFX/Damage
@onready var sfx_death: AudioStreamPlayer2D = $SFX/Death
@onready var body_collision: CollisionShape2D = $CollisionShape2D

var is_dying: bool = false

func _ready() -> void:
	add_to_group("enemy")
	base_y = global_position.y

	if stats == null:
		stats = EnemyStats.new()

	hp = stats.max_hp
	patrol_dir = stats.start_patrol_dir
	_update_health_bar()

	if detection_area:
		detection_area.body_entered.connect(_on_detect_enter)
		detection_area.body_exited.connect(_on_detect_exit)

	if fire_timer:
		fire_timer.wait_time = stats.fire_cooldown
		fire_timer.timeout.connect(_on_fire_timer_timeout)

	if contact_area:
		contact_area.body_entered.connect(_on_contact_body_entered)
		
	if animated_sprite:
		animated_sprite.play("default")


func _update_health_bar() -> void:
	if not health_bar:
		return

	health_bar.max_value = stats.max_hp
	health_bar.value = clamp(hp, 0, stats.max_hp)

	var ratio := 0.0
	if stats.max_hp > 0:
		ratio = float(hp) / float(stats.max_hp)

	var col: Color
	if ratio <= 0.25:
		col = Color(1, 0, 0)
	elif ratio <= 0.5:
		col = Color(1, 1, 0)
	else:
		col = Color(0, 1, 0)

	health_bar.modulate = col


func _physics_process(delta: float) -> void:
	
	if is_dying:
		velocity = Vector2.ZERO
		return

	t += delta

	var dir := Vector2.ZERO
	var speed := 0.0

	# Patrol baseline
	if stats.enable_patrol:
		dir = Vector2(patrol_dir, 0)
		speed = stats.patrol_speed

	# Chase player
	if stats.enable_chase and player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
		speed = stats.chase_speed

	# Shooting
	if stats.enable_shooting and can_fire and player and is_instance_valid(player):
		_fire_at_player()
			
	if stats.is_grounded:
		dir.y = 0.0

	# Facing + contact hitbox 
	if dir.x != 0.0:
		facing_dir = 1 if dir.x > 0.0 else -1
		
		# Flip the sprite based on direction
		if animated_sprite:
			animated_sprite.flip_h = (facing_dir == -1)

	if stats.enable_contact_damage and contact_area:
		var base_offset := 16.0
		contact_area.position.x = base_offset * facing_dir
		contact_area.position.y = 0.0

	# Vertical behavior
	if stats.enable_bob:
		var bob := sin(t * stats.bob_frequency) * stats.bob_amplitude
		global_position.y = base_y + bob

	# Movement 
	velocity = dir * speed
	move_and_slide()

	if is_on_wall():
		patrol_dir *= -1


func _on_contact_body_entered(body: Node2D) -> void:
	if stats == null or not stats.enable_contact_damage:
		return
	
	if not body.is_in_group("player"):
		return

	var dir := (body.global_position - global_position).normalized()
	var knockback := dir * stats.contact_knockback_force

	if body.has_method("apply_contact_damage"):
		body.apply_contact_damage(stats.contact_damage, knockback)
	elif body.has_method("apply_damage"):
		body.apply_damage(stats.contact_damage, knockback)


func _fire_at_player() -> void:
	can_fire = false
	if fire_timer:
		fire_timer.start()

	if projectile_scene == null:
		return

	var proj := projectile_scene.instantiate()
	get_parent().add_child(proj)

	proj.global_position = global_position
	var shoot_dir := (player.global_position - global_position).normalized()

	if proj.has_method("setup"):
		proj.speed = stats.projectile_speed
		proj.setup(
			shoot_dir,
			player if stats.use_homing else null,
			10,
			stats.homing_strength if stats.use_homing else 0.0
		)


func _on_fire_timer_timeout() -> void:
	can_fire = true


func _on_detect_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body


func _on_detect_exit(body: Node2D) -> void:
	if body == player:
		# keep moving in the direction player exited
		var side = sign(body.global_position.x - global_position.x)
		if side != 0:
			patrol_dir = int(side)
		player = null


func apply_damage(amount: int, knockback: Vector2) -> void:
	if is_dying:
		return
		
	hp -= amount
	_update_health_bar()

	if sfx_damage:
		sfx_damage.play()

	if hp <= 0:
		_die()
		
func _die() -> void:
	if is_dying:
		return
	is_dying = true

	if body_collision:
		body_collision.disabled = true
	if contact_area:
		contact_area.monitoring = false
		contact_area.monitorable = false

	if sfx_death:
		sfx_death.play()
		await sfx_death.finished

	queue_free()
