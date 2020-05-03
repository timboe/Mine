tool
extends MultiMeshInstance

enum Mountain {GOING_UP, GOING_DOWN}
enum Slope {STEEP, SHALLOW}
var mountain : int = Mountain.GOING_UP
var slope : int = Slope.STEEP

onready var rand := RandomNumberGenerator.new()

# Cannot have min=0 here as != 0 tells the shader to do the mountain
const MOUNTAIN_LIMITS := Vector2(0.1, 1.0)

func mountain_range(var x : float) -> float:
	var s : float
	match slope:
		Slope.STEEP:
			s = rand.randf_range(-0.20, 0.30)
		Slope.SHALLOW:
			s = rand.randf_range(-0.1, 0.20)
	var r : float
	match mountain:
		Mountain.GOING_UP:
			r = x + s
		Mountain.GOING_DOWN:
			r = x - s
	if r >= MOUNTAIN_LIMITS.y:
		r = MOUNTAIN_LIMITS.y
		mountain = Mountain.GOING_DOWN
	elif r <= MOUNTAIN_LIMITS.x:
		r = MOUNTAIN_LIMITS.x
		mountain = Mountain.GOING_UP
	elif rand.randf() > 0.75:
		mountain = Mountain.GOING_UP if rand.randf() > 0.5 else Mountain.GOING_DOWN
		slope = Slope.STEEP if rand.randf() > 0.5 else Slope.SHALLOW
	return r

func _ready():
	rand.randomize()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.color_format = MultiMesh.COLOR_NONE
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_8BIT
	var grid_mesh_instance : MeshInstance = $"../Grid"
	var grid_mesh : Mesh = grid_mesh_instance.mesh.duplicate()
	var material : ShaderMaterial = preload("res://materials/Grid_material.tres").duplicate()
	material.set_shader_param("SPEED", 1.0)
	material.set_shader_param("SHAPE_SIZE", grid_mesh_instance.STEP_SIZE)
	material.set_shader_param("SHAPE_LENGTH", grid_mesh_instance.LENGTH)
	material.set_shader_param("MOUNTAIN_MAX_HEIGHT", 200.0)
	material.set_shader_param("MOUNTAIN_MAX_COLOUR", 0.25) # Fraction of height
	material.set_shader_param("MOUNTAIN_TOP_COLOUR", Color.magenta)
	material.set_shader_param("MOUNTAIN_Y_FLOOR", translation.y)
	material.set_shader_param("SCROLL", true)
	grid_mesh.surface_set_material(0, material)
	multimesh.mesh = grid_mesh
	# Done setup - cannot change anything else after increasing instance_count
	var extent : int = 50
	multimesh.instance_count = extent*extent
	var count : int = -1
	var previous_mountain : float = 0.1
	for x in range(-extent/2, extent/2):
		for z in range(-extent/2, extent/2):
			count += 1
			assert(count < multimesh.instance_count)
			var custom := Color()
			if x == 5:
				custom.r = previous_mountain
				custom.g = mountain_range(custom.r)
				custom.b = mountain_range(custom.g)
				custom.a = mountain_range(custom.b)
				previous_mountain = custom.a
			multimesh.set_instance_custom_data(count, custom)
			multimesh.set_instance_transform(count, Transform(Basis(),
			  Vector3(x * grid_mesh_instance.LENGTH, 0, z * grid_mesh_instance.LENGTH)))
