#de code voor VassiePassie

extends CharacterBody3D

var crouch = false

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
var CROUCH_SPEED = 3.0
const SLIDE_SPEED = 100.0
var JUMP_VELOCITY = 5
const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 11

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var anim_player = $AnimationPlayer


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta):
	#print(velocity.y)
	
	# Add the gravity.
	if not is_on_floor():
		#print("is_on_floor")
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		


	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Handle Crouch.
	if Input.is_action_pressed("crouch"):
		scale.y = 0.5
		crouch = true
		speed = CROUCH_SPEED
		
	else:
		scale.y = 1.047
		crouch = false


	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 2.0)

	move_and_slide()

	if crouch == true:
		print("De speler is aan het hurken")
		CROUCH_SPEED = 10
		await get_tree().create_timer(1).timeout
		CROUCH_SPEED = 3
	else:
		CROUCH_SPEED = 3

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _process(delta):
	if Input.is_action_just_pressed("attack"):
		anim_player.play("SwordSlash")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "SwordSlash":
		anim_player.play("Idle")

func _on_area_3d_area_entered(area):
	if area.name == "Wall":
		print("collided")
		JUMP_VELOCITY = 0
		gravity = 9999
	
func _on_area_3d_area_exited(area):
	if area.name == "Wall":
		print("Player verlaat muur")
		JUMP_VELOCITY = 5
		gravity = 11

