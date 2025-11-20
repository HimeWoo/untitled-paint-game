extends CharacterBody2D

# ---------- MOVEMENT VARIABLES ----------
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 700.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.5

var jumps_left = 1
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 0

# ---------- MELEE ATTACK VARIABLES ---------
const ATTACK_COOLDOWN = 0.4
var is_attacking = false 
var can_attack = true
var inventory: Inventory = Inventory.new()
var last_paint_color = null 

@export var attack_scene: PackedScene = preload("res://scenes/MeleeAttack.tscn")

func _ready() -> void:
	jumps_left = 1
	
	# --- ADDED FOR TESTING ---
	# We need items in the inventory to test keys 1, 2, and 3!
	# Assuming PaintColor.Colors has RED, BLUE, GREEN
	inventory.add_color(PaintColor.Colors.RED)   # Key 1
	inventory.add_color(PaintColor.Colors.BLUE)  # Key 2
	inventory.add_color(PaintColor.Colors.GREEN) # Key 3
	
	inventory.select_index(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inv_next"):
		inventory.select_next(1)
	elif event.is_action_pressed("inv_prev"):
		inventory.select_next(-1)
	elif event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		var num := key_event.keycode - KEY_1 
		
		# Keys 1-9 passed to inventory
		# The inventory.select_index() method handles the bounds check!
		if num >= 0: 
			inventory.select_index(num)

func _physics_process(delta: float) -> void:
	# --- FIXED THIS SECTION ---
	# OLD: var current_paint_color = PaintColor.Colors.find_key(inventory._contents.get(0))
	
	# NEW: Get the ACTUAL selected color or null
	var selected_item = inventory.current_color()
	
	# Check if we actually have a color selected (not null)
	if selected_item != null:
		var current_paint_color = PaintColor.Colors.find_key(selected_item)
		
		if current_paint_color != last_paint_color:
			print("Switched to: ", current_paint_color)
			last_paint_color = current_paint_color
	# --------------------------

	# ... (Rest of your movement code remains exactly the same) ...
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta
	elif is_on_floor():
		jumps_left = 1 

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
		dash_direction = int(right) - int(left)
		if dash_direction == 0:
			dash_direction = sign(velocity.x) if velocity.x != 0 else 1
		start_dash()
	if Input.is_action_just_pressed("melee_attack"):
		perform_slash()

	if is_dashing:
		dash_timer -= delta
		velocity.y = 0 
		velocity.x = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			end_dash()
	else:
		var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
		var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
		var direction := int(right) - int(left)

		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	move_and_slide()

func start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN

func end_dash() -> void:
	is_dashing = false

func perform_slash() -> void:
	is_attacking = true
	can_attack = false
	
	# Instantiate the attack scene
	var attack_instance = attack_scene.instantiate()
	
	# Add it as a child of the player (so it moves with you)
	# OR add it to the main scene (get_parent().add_child) if you want the slash 
	# to stay in place while you move away.
	add_child(attack_instance)
	
	# Initialize it
	# 'facing_direction' should be 1 or -1 from your movement logic
	attack_instance.start_attack(self, 1)
	
	# Wait for cooldown
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	is_attacking = false
	can_attack = true
