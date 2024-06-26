#de code voor VassiePassie

extends CharacterBody3D

var crouch = false
var holdSpell = false
var spell

var jumpMax = 2;
var doubleJump = 0;
var double_jumped = false;

var holdSpeedSpell = false;

var speed
var WALK_SPEED = 5.0
var SPRINT_SPEED = 8.0
var CROUCH_SPEED = 3.0
var JUMP_VELOCITY = 7
const SENSITIVITY = 0.004
"mesh"
#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
var BASE_FOV = 75.0
const FOV_CHANGE = 1.5
const SPEED_FOV = 90.0

var paused = false

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
	print(holdSpell)
	
	
	# Add the gravity.
	if not is_on_floor():
		#print("is_on_floor")
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("jump") and (holdSpell == true) and doubleJump < jumpMax:
		doubleJump +=1
		velocity.y = JUMP_VELOCITY
	elif is_on_floor():
		doubleJump = 0
	elif doubleJump >= jumpMax:
		holdSpell = false;

	if holdSpell == true:
		spell = "Je kan double jumpen!"
	elif holdSpeedSpell == true:
		spell = "Speed boost"
	else:
		spell = ""
	$Label.text = str(spell)

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
		BASE_FOV = SPEED_FOV
		CROUCH_SPEED = 10
		velocity.x = velocity.x*1.02
		await get_tree().create_timer(3).timeout
		CROUCH_SPEED = 3
		BASE_FOV = 75
	else:
		CROUCH_SPEED = 3
		BASE_FOV = 75

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func _on_area_3d_area_entered(area):	
	if area.name == "JumpSpell":
		holdSpell = true;
	elif area.name == "SpeedSpell":
		holdSpeedSpell = true;
		
	var parent_node = area.get_parent()
	if parent_node:
		parent_node.queue_free()
		
	while holdSpeedSpell == true:
		BASE_FOV = 110
		SPRINT_SPEED = SPRINT_SPEED*2;
		WALK_SPEED = WALK_SPEED*2;
		CROUCH_SPEED = CROUCH_SPEED*2;
		await get_tree().create_timer(6).timeout
		SPRINT_SPEED = SPRINT_SPEED/2;
		WALK_SPEED = WALK_SPEED/2;
		CROUCH_SPEED = 12;
		holdSpeedSpell = false
		BASE_FOV = 75
		
		
func _process(delta):
	if Input.is_action_just_pressed("attack"):
		anim_player.play("SwordSlash")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "SwordSlash":
		anim_player.play("Idle")

