extends CharacterBody3D


@export var mouse_sensitivity: float = 0.0013
@export var player_id: int = 0
@export var turn_speed = 2.5
@export var acceleration = 12.0
@export var deceleration = 16.0
@export var wall_deceleration = 150.0
@export var max_forward_speed = 100.0
@export var max_backward_speed = 8.0
@export var model: Node3D
@export var health = 100.0
@export var base_knockback = 6.0
@export var percent_multiplier = 0.08
@export var knockback_decay := 14.0
@export var slow_motion_ratio = 10.0
@export var speed_meter: SubViewportContainer

var camera: Camera3D
var out_of_bounds_timer: Timer
var slow_down_timer: Timer
var smash_percentage_panel: PanelContainer
var timer_panel: Panel
var impact_frame: MeshInstance3D
var death_screen: TextureRect
var javelin: Area3D
var smash_percent = 0
var current_speed = 0.0
var knockback_velocity: Vector3 = Vector3.ZERO
var out_of_bounds = false
var is_dead = false
var control_enabled = true

enum State {IDLE, WALK, RUN}

var state:State = State.IDLE

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = $Camera3D
	out_of_bounds_timer = $OutOfBoundsTimer
	slow_down_timer = $TimeSlowDown
	smash_percentage_panel = $SmashPercentageLabel
	timer_panel = $TimerPanel
	death_screen = $"Control/MarginContainer/YOU DIED"
	death_screen.modulate.a = 0 # will fade in upon death
	impact_frame = $Camera3D/Impact


func _physics_process(delta: float) -> void:
	# disable controls upon death to force horse death animation
	if is_dead:
		return

	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var acceleration_trigger_strength = 0
	var deceleration_trigger_strength = 0
	if control_enabled:
	# Strength of trigger presses
		acceleration_trigger_strength = Input.get_action_strength("accelerate_%s" % [player_id])
		deceleration_trigger_strength = Input.get_action_strength("decelerate_%s" % [player_id])

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
	var move_direction = 0
	var move_velocity = 0
	if control_enabled:
		move_direction = -transform.basis.z
		move_velocity = move_direction * current_speed

	velocity.x = move_velocity.x + knockback_velocity.x
	velocity.z = move_velocity.z + knockback_velocity.z


	# Turning
	var turn_direction = Input.get_axis("turn_right_%s" % [player_id], "turn_left_%s" % [player_id])
	if turn_direction != 0:
		rotate_y(turn_direction * turn_speed * delta)
		
	# STATE MACHINE process
	if current_speed >= 20.0:
		switch_state(State.RUN)
	elif current_speed != 0:
		switch_state(State.WALK)
	else:
		switch_state(State.IDLE)
	
	# Mouse (Player 1 only)
	if player_id == 1:
		var mouse_delta := Input.get_last_mouse_velocity()
		rotate_y(-mouse_delta.x * mouse_sensitivity * delta)
	
	# Slow down speed upon collision
	if is_on_wall():
		current_speed = move_toward(current_speed, 0.0, wall_deceleration * delta)
		
	# Decay knockback over time
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
	
	# Constantly update timer
	timer_panel.label.text = "TIME: %s" % [snapped(out_of_bounds_timer.time_left, 0.1)]
	
	#Speed meter update
	(speed_meter.material as ShaderMaterial).set_shader_parameter("rot_y_deg", max(-current_speed,-85))
	(speed_meter.get_child(0).get_child(0).get_child(0) as Label).text = str("%0.1f" % current_speed,"")
	(speed_meter.get_child(0).get_child(0) as Panel).modulate = Color(current_speed/2, current_speed/3, 0)
	
	move_and_slide()
	
func switch_state(s: State): #STATE MACHINE switcher
	if state == s:
		return
		
	state = s
	match state:
		State.IDLE:
			model.playIdleHorse()
			pass 
		State.WALK:
			model.playSlowHorse()
			pass 
		State.RUN:
			model.playFastHorse()
			pass 
	
# allows you to press escape to view mouse cursor
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		if Input.is_action_just_pressed("mouse_capture"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# player loses health when javelin connects to their hurtbox
func _on_hurtbox_area_entered(area: Area3D) -> void:
	var enemy = area.get_parent()
	var enemy_speed = enemy.current_speed
	
	if enemy_speed > 10.0:
		smash_percent += enemy_speed
		smash_percent = clamp(smash_percent, 0.0, 300.0)
		smash_percentage_panel.update_label(smash_percent)
		
		# Horizontal knockback direction
		var knockback_dir = global_position - enemy.global_position
		knockback_dir.y = 0.0
		
		if knockback_dir.length() == 0:
			knockback_dir = -transform.basis.z
		
		knockback_dir = knockback_dir.normalized()
		
		# Knockback strength
		var knockback_strength = base_knockback * enemy_speed/30 + smash_percent * percent_multiplier
		knockback_velocity = knockback_dir * knockback_strength
		print("Smash %:", smash_percent, " Knockback:", knockback_strength)
		
			# slow down time and potentially trigger impact frame
		slow_down_timer.wait_time = clamp((knockback_strength / slow_motion_ratio), 0.01, 0.1)
		slow_down_timer.start()
		print(slow_down_timer.wait_time)
		Engine.set_time_scale(0.1)
		if knockback_strength > 36.0:
			impact_frame.visible = true
		
		#Invlun + uncontrollable time
		(get_node("hurtbox") as Area3D).monitoring = false
		await get_tree().create_timer(0.5).timeout
		get_node("hurtbox").monitoring = true


func start_out_of_bounds_timer():
	if out_of_bounds:
		return
	
	out_of_bounds = true
	out_of_bounds_timer.start()
	timer_panel.visible = true


func cancel_out_of_bounds_timer():
	if not out_of_bounds:
		return
	
	out_of_bounds = false
	out_of_bounds_timer.stop()
	timer_panel.visible = false


func _on_out_of_bounds_timer_timeout() -> void:
	print("Player", player_id, "KO'd!")
	is_dead = true
	death_screen.fade_in()
	model.playDeadHorse()


func _on_time_slow_down_timeout() -> void:
	print("DONE")
	Engine.set_time_scale(1.0)
	impact_frame.visible = false
