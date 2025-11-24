extends CharacterBody2D

@export var hp: int = 20

@export var patrol_speed: float = 20.0
@export var chase_speed: float = 120.0
@export var bob_amplitude: float = 10.0
@export var bob_frequency: float = 3.0

@export var fire_cooldown: float = 1.6
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 350.0
@export var use_homing: bool = false
@export var homing_strength: float = 3.0

var player: Node2D = null
var base_y: float
var t: float = 0.0
var patrol_dir: int = -1
var can_fire: bool = true

@onready var detection_area: Area2D = $DetectionArea
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	add_to_group("enemy")
	base_y = global_position.y

	detection_area.body_entered.connect(_on_detect_enter)
	detection_area.body_exited.connect(_on_detect_exit)

	fire_timer.wait_time = fire_cooldown
	fire_timer.timeout.connect(_on_fire_timer_timeout)

func _physics_process(delta: float) -> void:
	t += delta

	var dir := Vector2(patrol_dir, 0)
	var speed := patrol_speed

	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
		speed = chase_speed
		if can_fire:
			_fire_at_player()

	# float bob
	var bob := sin(t * bob_frequency) * bob_amplitude
	global_position.y = base_y + bob

	velocity = dir * speed
	move_and_slide()

	if is_on_wall():
		patrol_dir *= -1

func _fire_at_player() -> void:
	can_fire = false
	fire_timer.start()
	if projectile_scene == null: return

	var proj := projectile_scene.instantiate()
	get_parent().add_child(proj)

	proj.global_position = global_position
	var shoot_dir := (player.global_position - global_position).normalized()

	if proj.has_method("setup"):
		proj.speed = projectile_speed
		proj.setup(
			shoot_dir,
			player if use_homing else null,
			5,
			homing_strength if use_homing else 0.0
		)

func _on_fire_timer_timeout() -> void:
	can_fire = true

func _on_detect_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detect_exit(body: Node2D) -> void:
	if body == player:
		player = null

# Matches melee_attack.gd convention
func apply_damage(amount: int, knockback: Vector2) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()
