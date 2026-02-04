extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.001

@onready var hotbar = $Hotbar
@onready var raycast = $Head/Camera3D/RayCast3D

var camera: Camera3D
var pitch: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = $Head/Camera3D
	
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("pickup"):
		if $Head/Camera3D/RayCast3D.is_colliding():
			var target = $Head/Camera3D/RayCast3D.get_collider()
	
	# hotbar controls
	for i in range(1, 5):
		if Input.is_action_just_pressed("slot_%d" % i):
			hotbar.select_slot(i - 1)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
		
		# Handle mouse escape from game window
		if Input.is_action_just_pressed("mouse_escape"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		# Handle mouse return to game window
		if Input.is_action_just_pressed("mouse_capture"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
