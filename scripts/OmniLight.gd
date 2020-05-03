extends OmniLight

const HEIGHT : float = 5.0
onready var camera : Camera = $"../Camera" 
onready var desired_height : float = translation.y

func _physics_process(var _delta : float):
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 500
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to)
	if not result.empty():
		translation.x = result.position.x
		translation.z = result.position.z
		desired_height = HEIGHT if result.position.y < 10.0 else 20.0 + HEIGHT
	translation.y += (desired_height - translation.y) * _delta * 10.0

