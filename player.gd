extends CharacterBody3D


@export var mouse_sensitivity: float = 0.001
@export var player_id: int = 0
@export var turn_speed = 2.5
@export var acceleration = 12.0
@export var deceleration = 16.0
@export var max_forward_speed = 100.0
@export var max_backward_speed = 8.0


var camera: Camera3D
var current_speed = 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = $Head/Camera3D


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Strength of trigger presses
	var acceleration_trigger_strength = Input.get_action_strength("accelerate_%s" % [player_id])
	var deceleration_trigger_strength = Input.get_action_strength("decelerate_%s" % [player_id])

	# Accelerate / decelerate
	if acceleration_trigger_strength > 0.0:
		current_speed += acceleration * acceleration_trigger_strength * delta
	elif deceleration_trigger_strength > 0.0:
		current_speed -= deceleration * deceleration_trigger_strength * delta
	else:
		current_speed = move_toward(current_speed, 0.0, deceleration * delta)

	# Different max speed for forwards or backwards
	if current_speed >= 0.0:
		current_speed = min(current_speed, max_forward_speed)
	else:
		current_speed = max(current_speed, -max_backward_speed)

	# Move in facing direction
	var move_direction = -transform.basis.z
	velocity.x = move_direction.x * current_speed
	velocity.z = move_direction.z * current_speed

	# Turning
	var turn_direction = Input.get_axis("turn_right_%s" % [player_id], "turn_left_%s" % [player_id])
	if turn_direction != 0:
		rotate_y(turn_direction * turn_speed * delta)

	move_and_slide()


# KEYBOARD AND MOUSE
# -------------------


# allows you to press escape to view mouse cursor
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		if Input.is_action_just_pressed("mouse_capture"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# mouse camera
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and player_id == 1:
		rotate_y(-event.relative.x * mouse_sensitivity)
