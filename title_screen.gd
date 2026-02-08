extends Control


var play_button: Button
var credits_button: Button
var quit_button: Button


func _ready() -> void:
	play_button = $"VBoxContainer/Play Button"
	credits_button = $"VBoxContainer/Credits Button"
	quit_button = $"VBoxContainer/Quit Button"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://credits.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
