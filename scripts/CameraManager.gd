extends Node

onready var player : KinematicBody = $"../Player"
onready var rot_helper : Camera = $"../Player/Rotation_Helper"
onready var fps_camera : Camera = $"../Player/Rotation_Helper/Camera"
onready var overhead_camera : Camera = $"../Camera"
onready var overhead_light : OmniLight = $"../OmniLight"
onready var tween : Tween = $Tween
onready var spawn_particles : Particles = $SpawnParticles

var quat_from : Quat
var quat_to : Quat

const TRANSITION_TIME : float = 2.0
const PLAYER_LOWER_DEPTH : float = 5.0
const UNPOSESS_DISTANCE := Vector2(-40, 50)

const TRANS := Tween.TRANS_SINE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
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
