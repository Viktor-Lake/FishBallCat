extends Control

func _process(delta):
	if Input.is_key_pressed(KEY_R):
		get_tree().change_scene("res://Scenes/Menu.tscn")
