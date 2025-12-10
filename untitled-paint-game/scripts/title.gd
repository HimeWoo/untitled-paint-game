extends Control 


func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
