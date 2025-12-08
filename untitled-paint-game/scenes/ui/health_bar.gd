class_name PlayerHealthBar
extends HBoxContainer

@onready var bar: ProgressBar = $Bar
@onready var label: Label = $HP

func _ready() -> void:
	if UISignals:
		UISignals.player_hp_changed.connect(_on_player_hp_changed)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	if bar == null:
		return

	bar.max_value = max_hp
	bar.value = clamp(current_hp, 0, max_hp)

	# Optional text
	if label:
		label.text = "HP %d/%d" % [current_hp, max_hp]

	# Optional color change like the enemy bar:
	var ratio := 0.0
	if max_hp > 0:
		ratio = float(current_hp) / float(max_hp)
	var col: Color
	if ratio <= 0.25:
		col = Color(1, 0, 0)
	elif ratio <= 0.75:
		col = Color(1, 1, 0)
	else:
		col = Color(0, 1, 0)
	bar.modulate = col
