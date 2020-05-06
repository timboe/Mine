extends Node

##############################
# Transition parameters

onready var player : KinematicBody = $"../Player"
onready var rot_helper : Camera = $"../Player/Rotation_Helper"
onready var fps_camera : Camera = $"../Player/Rotation_Helper/Camera"
onready var overhead_camera : Camera = $"../Camera"
onready var overhead_light : OmniLight = $"../OmniLight"
onready var tween : Tween = $Tween
onready var spawn_particles : Particles = $SpawnParticles
#onready var chroma : ShaderMaterial = $"../Camera/Chroma".mesh.surface_get_material(0)

var quat_from : Quat
var quat_to : Quat

const TRANSITION_TIME : float = 2.0
const PLAYER_LOWER_DEPTH : float = 5.0
const UNPOSESS_DISTANCE := Vector2(-40, 50)

const TRANS := Tween.TRANS_SINE

##############################
# Shake parameters

export var shake_speed := 1.0
export var shake_decay := 0.5
export var noise : OpenSimplexNoise

const RUMBLE_OFFSET : float = 0.75
const RUMBLE_FALLOFF : float = 100.0

const CHROMA_OFFSET_BASE := 15.0
const CHROMA_OFFSET_MAX_ADD := 100

const CHROMA_VIN_BASE := 0.4
const CHROMA_VIN_MAX_ADD := 0.2

var trauma := 0.0
var time := 0.0
var linger := 0.0

###############

func _process(delta):
	apply_shake(delta)
	decay_trauma(delta)
	
func quat_transform(var amount : float):
	var mid = quat_from.slerp(quat_to, amount)
	overhead_camera.transform.basis = Basis(mid)

func _input(event):
	if event.is_action_pressed("capture_toggle"):
		match GlobalVars.camera_status:
			GlobalVars.CameraStatus.OVERHEAD:
				to_fps_cam_start()
			GlobalVars.CameraStatus.FPS:
				to_overhead_cam_start()
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func to_fps_cam_start():
	GlobalVars.camera_status = GlobalVars.CameraStatus.TO_FPS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if GlobalVars.SELECTED_NODE != null:
		GlobalVars.SELECTED_NODE.call("_on_StaticBody_mouse_exited")
	player.transform.origin = overhead_light.to_global(Vector3.ZERO)
	player.transform.origin.y = 0 if overhead_light.floor_lowered else GlobalVars.FLOOR_HEIGHT
	player.look_at( overhead_camera.to_global(Vector3.ZERO), Vector3.UP)
	player.rotate_object_local(Vector3.UP, PI) # Actually, look AWAY
	# Keep the actual rotation around x on the camera
	#TODO clamp isn't working
	fps_camera.rotation.x = player.rotation.x
	fps_camera.rotation.x = clamp(fps_camera.rotation.x, -70, 70)
	rot_helper.rotation.x = fps_camera.rotation.x
	player.rotation.x = 0
	var player_target = player.to_global(Vector3.ZERO)
	var camera_target = fps_camera.to_global(Vector3.ZERO)
	quat_from = Quat(overhead_camera.transform.basis)
	quat_to = Quat(fps_camera.get_global_transform().basis)
	# Move the spawn effect here too now
	spawn_particles.transform.origin = player.transform.origin
	spawn_particles.emitting = true
	player.transform.origin.y -= PLAYER_LOWER_DEPTH # Hide underneath

	tween.interpolate_property(player, "translation",
		null, player_target, TRANSITION_TIME, TRANS, Tween.EASE_IN_OUT)
	tween.interpolate_property(overhead_camera, "translation",
		overhead_camera.to_global(Vector3.ZERO), camera_target,
		TRANSITION_TIME, TRANS, Tween.EASE_OUT)
	tween.interpolate_method(self, "quat_transform",
		0.0, 1.0, TRANSITION_TIME, TRANS, Tween.EASE_OUT)
	tween.interpolate_callback(self, TRANSITION_TIME, "to_fps_cam_end")
	tween.start()

func to_fps_cam_end():
	GlobalVars.camera_status = GlobalVars.CameraStatus.FPS
	overhead_camera.current = false
	fps_camera.current = true
	spawn_particles.emitting = false

func to_overhead_cam_start():
	GlobalVars.camera_status = GlobalVars.CameraStatus.TO_OVERHEAD
	var start : Vector3 = fps_camera.to_global(Vector3.ZERO)
	var cam_xform = fps_camera.get_global_transform()
	# Go first to the final position
	overhead_camera.transform = cam_xform
	# Move back by 20m and set to 50m height
	overhead_camera.transform.origin += -cam_xform.basis.z * UNPOSESS_DISTANCE.x
	overhead_camera.transform.origin.y = UNPOSESS_DISTANCE.y
	overhead_camera.look_at(start, Vector3.UP)
	var target_tf : Transform = overhead_camera.transform
	var player_target : Vector3 = player.to_global(Vector3.ZERO)
	player_target.y -= PLAYER_LOWER_DEPTH
	# Set to same as the fps_cam
	overhead_camera.transform = cam_xform
	overhead_camera.current = true
	fps_camera.current = false
	quat_from = Quat(cam_xform.basis)
	quat_to = Quat(target_tf.basis)
	tween.interpolate_property(overhead_camera, "translation",
		null, target_tf.origin, TRANSITION_TIME, TRANS, Tween.EASE_OUT)
	tween.interpolate_property(player, "translation",
		null, player_target, TRANSITION_TIME, TRANS, Tween.EASE_OUT)
	tween.interpolate_method(self, "quat_transform",
		0.0, 1.0, TRANSITION_TIME, TRANS, Tween.EASE_OUT)
	tween.interpolate_callback(self, TRANSITION_TIME, "to_overhead_cam_end")
	tween.start()
	spawn_particles.transform.origin = player.transform.origin
	spawn_particles.emitting = true

func to_overhead_cam_end():
	GlobalVars.camera_status = GlobalVars.CameraStatus.OVERHEAD
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	spawn_particles.emitting = false
	
func add_trauma(var amount : float, var from, var add_linger):
	var c : Vector3 = overhead_camera.to_global(Vector3.ZERO) if overhead_camera.current else fps_camera.to_global(Vector3.ZERO)
	var d : float = from.distance_to(c) if from is Vector3 else 0.0
	linger = max(linger, add_linger) if add_linger is float else linger
	if d > RUMBLE_FALLOFF:
		amount *= (RUMBLE_FALLOFF / d)
	trauma = min(trauma + amount, 1.0)
 
func decay_trauma(var delta: float):
	var change := shake_decay * delta
	trauma = max(trauma - change, 0.0)
	linger = max(linger - delta, 0.0)
 
# apply shake to starting camera position
func apply_shake(var delta : float):
	# using a magic number here to get a pleasing effect at speed 1.0
	time += delta * shake_speed * 5000.0
	var trauma_mod : float = trauma
	if linger > 0:
		trauma_mod = min(trauma + 0.4, 1.0)
	if trauma_mod == 0:
		return
	var shake := trauma_mod * trauma_mod
	var offset_x := RUMBLE_OFFSET * shake * noise.get_noise_2d(0, time)
	var offset_y := RUMBLE_OFFSET * shake * noise.get_noise_2d(time, 0)
	if fps_camera.current:
		fps_camera.h_offset = offset_x
		fps_camera.v_offset = offset_y
	else:
		overhead_camera.h_offset = offset_x
		overhead_camera.v_offset = offset_y
	#chroma.set_shader_param("Offset", CHROMA_OFFSET_BASE + (CHROMA_OFFSET_MAX_ADD * shake))
	#chroma.set_shader_param("Encroach", CHROMA_VIN_BASE + (CHROMA_VIN_MAX_ADD * shake))
	var chroma : ShaderMaterial = $"../Camera/Chroma".mesh.surface_get_material(0)
	chroma.set_shader_param("Offset", 100.0)
	chroma.set_shader_param("Encroach", 1.0)
