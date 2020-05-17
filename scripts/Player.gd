extends KinematicBody

const GRAVITY = -60
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL = 4.5

var dir = Vector3()
var jaggies : float = 0
var mouse_initial : bool = true

const JAGGIES_UPDATE := 0.05

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

onready var camera : Camera = $Rotation_Helper/Camera
onready var rotation_helper : Spatial = $Rotation_Helper
onready var ray : RayCast = $Rotation_Helper/RayCast
onready var ray_render : ImmediateGeometry = $Rotation_Helper/RayRender
onready var rand := RandomNumberGenerator.new()

var MOUSE_SENSITIVITY = 0.4

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)

func process_input(delta):
	if !camera.current:
		return
	
	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------
	
	# Casting and selecting
	if Input.is_mouse_button_pressed(1):
		jaggies += delta
		ray.force_raycast_update()
		if jaggies > JAGGIES_UPDATE:
			jaggies -= JAGGIES_UPDATE
			ray_render.clear()
			if ray.is_colliding():
				var local = ray_render.get_global_transform().xform_inv( ray.get_collision_point() )
				draw_jaggy_to(local.y)
		var wall = ray.get_collider()
		if mouse_initial:
			mouse_initial = false
			if wall != null and wall.has_method("get_state"):
				GlobalVars.SELECTING_MODE = (wall.call("get_state") == TileElement.State.BUILT)
			else:
				GlobalVars.SELECTING_MODE = true
		if wall != null and wall.has_method("_on_StaticBody_mouse_entered"):
			wall.call("_on_StaticBody_mouse_entered")
			wall.call("_on_StaticBody_mouse_exited") # We don't want the hover highlight in FPS
	else:
		ray_render.clear()
		mouse_initial = true
		
func draw_jaggy_to(var dist : float):
	ray_render.begin(Mesh.PRIMITIVE_LINE_STRIP)
	ray_render.set_color(Color.white)
	ray_render.add_vertex(Vector3.ZERO)
	var pos := Vector3.ZERO
	ray_render.add_vertex(pos)
	# Note, in player coordinates, -y is forwards....
	while pos.y > dist:
		pos.x += rand.randf_range(-0.1, 0.1)
		pos.z += rand.randf_range(-0.1, 0.1)
		pos.y += rand.randf_range(-3.0, 1.0) if pos.y > -5.0 else rand.randf_range(-3.0, 0.0)
		if pos.y <= dist:
			pos = Vector3(0, dist, 0)
		ray_render.add_vertex(pos)
	#for i in range( rand.randi_range(0,5) ):
	#	ray_render.add_vertex(Vector3.ZERO)
	#	ray_render.add_vertex(Vector3(rand.randf_range(-0.1, 0.1), dist, rand.randf_range(-0.1, 0.1)))
	ray_render.end()

func process_movement(delta):
	if !camera.current:
		return
		
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * GRAVITY

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func _input(event):
	#print("PL ", rotation_degrees)
	#print("RH " ,rotation_helper.rotation_degrees)
	
	if !camera.current:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY) * -1)

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
