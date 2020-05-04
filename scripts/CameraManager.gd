extends Node

onready var player : KinematicBody = $"../Player"
onready var fps_camera : Camera = $"../Player/Rotation_Helper/Camera"
onready var rot_helper : Spatial = $"../Player/Rotation_Helper"
onready var overhead_camera : Camera = $"../Camera"
onready var overhead_light : OmniLight = $"../OmniLight"
onready var tween : Tween = $Tween

var overhead_quat : Quat
var fps_quat : Quat

const TRANSITION_TIME : float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func quat_transform_overhead_to_fps(var amount : float):
	var mid = overhead_quat.slerp(fps_quat, amount)
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
	player.translation = overhead_light.to_global(Vector3.ZERO)
	player.translation.y = 0 if overhead_light.floor_lowered else GlobalVars.FLOOR_HEIGHT
	player.look_at( overhead_camera.to_global(Vector3.ZERO), Vector3.UP)
	player.rotate_object_local(Vector3.UP, PI) # Actually, look AWAY
	var player_target = player.to_global(Vector3.ZERO)
	var camera_target = fps_camera.to_global(Vector3.ZERO)
	overhead_quat = Quat(overhead_camera.transform.basis)
	fps_quat = Quat(player.transform.basis)
	player.transform.origin.y -= 3.0 # Hide underneath
	# Keep the actual rotation around x on the helper only
	rot_helper.rotation.x = player.rotation.x
	player.rotation.x = 0
	#print("GOING TO " , fps_camera.to_global(Vector3.ZERO))
	tween.interpolate_property(player, "translation",
		null, player_target, TRANSITION_TIME, Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.interpolate_property(overhead_camera, "translation",
		overhead_camera.to_global(Vector3.ZERO), camera_target, 2.0, Tween.TRANS_CIRC, Tween.EASE_IN)
	tween.interpolate_method(self, "quat_transform_overhead_to_fps",
		0.0, 1.0, TRANSITION_TIME, Tween.TRANS_CIRC, Tween.EASE_IN)
	tween.interpolate_callback(self, TRANSITION_TIME, "to_fps_cam_end")
	tween.start()

func to_fps_cam_end():
	GlobalVars.camera_status = GlobalVars.CameraStatus.FPS
	overhead_camera.current = false
	fps_camera.current = true
	#print("B Gcam height loc ", root_camera.translation, " glob ",root_camera.to_global(root_camera.translation))
	#print("B  cam height loc ", camera.translation, " glob ",camera.to_global(camera.translation))
	print("AT " , overhead_camera.to_global(Vector3.ZERO))

func to_overhead_cam_start():
	GlobalVars.camera_status = GlobalVars.CameraStatus.TO_OVERHEAD
	overhead_camera.translation = fps_camera.to_global(fps_camera.translation)
	overhead_camera.rotation = player.rotation
	var target_pos = overhead_camera.translation
	target_pos.y += 20
	#var target_rot = 
	overhead_camera.current = true
	fps_camera.current = false
	tween.interpolate_property(overhead_camera, "translation",
		null, target_pos, 2.0, Tween.TRANS_CIRC, Tween.EASE_IN)
	#tween.interpolate_property(overhead_camera, "rotation",
	#	rotation, overhead_camera.rotation, 2.0, Tween.TRANS_CIRC, Tween.EASE_IN)
	tween.interpolate_callback(self, 3.0, "to_overhead_cam_end")
	tween.start()

func to_overhead_cam_end():
	GlobalVars.camera_status = GlobalVars.CameraStatus.OVERHEAD
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
