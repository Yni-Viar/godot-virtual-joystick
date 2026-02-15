@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("Godot Virtual Joystick", "Control", load("res://addons/godot-virtual-joystick/virtual-joystick.gd"), load("res://addons/godot-virtual-joystick/VirtualJoystick.svg"))


func _exit_tree() -> void:
	remove_custom_type("Godot Virtual Joystick")
