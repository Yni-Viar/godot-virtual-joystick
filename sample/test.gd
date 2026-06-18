extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		$Sprite2D.rotate(PI / 360)
	elif Input.is_action_pressed("ui_left"):
		$Sprite2D.rotate(-PI / 360)
