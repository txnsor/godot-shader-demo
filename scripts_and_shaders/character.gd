extends CharacterBody3D

# Movement Logic
# Basic Controller

var input_direction : Vector2

@export var look_sens: float = 0.009
@export var speed = 5.0
@export var acceleration = 60.0
@export var jump_velocity = 5.0
@export var air_control = 5.0
@export var air_resistance = 2.0

@onready var head = $Pivot
@onready var camera = $Pivot/Camera3D

func _ready(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	# looking
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * look_sens)
		camera.rotate_x(-event.relative.y * look_sens)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2.0, PI/2.0)

	if Input.is_action_just_pressed("escape"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if not is_on_floor():  velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = jump_velocity

	input_direction = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	var target_velocity = direction * speed
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if is_on_floor():
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	else:
		if direction:
			horizontal_velocity = horizontal_velocity.move_toward(target_velocity, air_control * delta)
		
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, air_resistance * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	
	move_and_slide()
