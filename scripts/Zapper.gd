extends RayCast

class_name Zapper

onready var ray_render : ImmediateGeometry = $RayRender
onready var rand = RandomNumberGenerator.new()

const JAGGIES_UPDATE := 0.1
var jaggies : float = 0.0


func _process(var delta : float):
	jaggies += delta
	if jaggies <= JAGGIES_UPDATE:
		return
	jaggies -= JAGGIES_UPDATE
	
	var target : Vector3
	if enabled:
		if is_colliding():
			target = get_collision_point()
		else:
			return
	else:
		target = cast_to
	
	ray_render.clear()
	draw_jaggy_to(target.y)
	
func draw_jaggy_to(var dist : float):
	ray_render.begin(Mesh.PRIMITIVE_LINE_STRIP)
	ray_render.set_color(Color.white)
	ray_render.add_vertex(Vector3.ZERO)
	var pos := Vector3.ZERO
	ray_render.add_vertex(pos)
	while pos.y < dist:
		pos.x += rand.randf_range(-0.2, 0.2)
		pos.z += rand.randf_range(-0.2, 0.2)
		pos.y += rand.randf_range(-1.0, 3.0)
		if pos.y >= dist:
			pos = Vector3(0, dist, 0)
		ray_render.add_vertex(pos)
	ray_render.end()
