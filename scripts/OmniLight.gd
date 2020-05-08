extends OmniLight

const HEIGHT : float = 5.0
var floor_lowered : bool = false
onready var camera : Camera = $"../Camera" 
onready var camera_manger : Node = $"../CameraManager"

onready var desired_height : float = translation.y

func _physics_process(var _delta : float):
	visible = camera.current
	if !visible:
		return
	if camera_manger.camera_status != camera_manger.CameraStatus.OVERHEAD:
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	var result = get_world().direct_space_state.intersect_ray(from, to,
		[], 2147483647, true, true)
	if not result.empty():
		translation.x = result.position.x
		translation.z = result.position.z
		desired_height = HEIGHT
		floor_lowered = true if result.position.y < GlobalVars.FLOOR_HEIGHT/2.0 else false
		desired_height += GlobalVars.FLOOR_HEIGHT if !floor_lowered else 0.0
	translation.y += (desired_height - translation.y) * _delta * 10.0

