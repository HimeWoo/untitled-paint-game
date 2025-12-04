extends Resource
class_name EnemyStats

@export_group("Core")
@export var max_hp: int = 20
@export var patrol_speed: float = 20.0
@export var chase_speed: float = 120.0
@export var start_patrol_dir: int = -1   # -1 = left, +1 = right

@export_group("Behavior Toggles")
@export var enable_patrol: bool = true
@export var enable_chase: bool = true
@export var enable_bob: bool = true 
@export var enable_shooting: bool = true
@export var enable_contact_damage: bool = true

@export_group("Floating / Bobbing")
@export var bob_amplitude: float = 12.0
@export var bob_frequency: float = 3.0

@export_group("Shooting")
@export var fire_cooldown: float = 1.6
@export var projectile_speed: float = 350.0
@export var use_homing: bool = false
@export var homing_strength: float = 1.0

@export_group("Contact Damage")
@export var contact_damage: int = 5
@export var contact_knockback_force: float = 0.0

@export_group("Movement Flags")
@export var is_grounded: bool = false
