tool
extends Spatial
class_name CairoTilesetGen

onready var base_material : SpatialMaterial = preload("res://materials/aluminium.tres")
onready var outline_material : ShaderMaterial = preload("res://materials/grid_edges.tres")
onready var disabled_material : ShaderMaterial = preload("res://materials/grid_faces.tres")

onready var cairo = $Cairo

var rand := RandomNumberGenerator.new()

onready var tile_script = preload("res://scripts/TileElement.gd")
var tileID : int = 0

const TRIPLETS : int = 5
const BORDER_TRIPLETS : int = 2

var one_down = false

func populate(var physics_body_instance : StaticBody):
	var mesh_instance = MeshInstance.new()
	mesh_instance.use_in_baked_light = true
	mesh_instance.set_script(tile_script)
	mesh_instance.set_mesh(cairo.cairo_mesh)
	# visible used as flag
	var mat : Material
	if physics_body_instance.visible:
		mat = base_material.duplicate() 
	else:
		mat = disabled_material
		if not Engine.editor_hint: mesh_instance.set_disabled()
	physics_body_instance.visible = true # Reset flag
	mesh_instance.set_surface_material(0, mat)
	mesh_instance.set_surface_material(1, outline_material)
	if not Engine.editor_hint: mesh_instance.set_id(tileID)
	tileID += 1
	physics_body_instance.add_child(mesh_instance)
	var cs = CollisionShape.new()
	cs.set_shape(cairo.cairo_mesh_shape)
	physics_body_instance.add_child(cs)
	var ray := RayCast.new()
	ray.translate(Vector3(cairo.UNIT/2.0, cairo.HEIGHT/2.0, cairo.UNIT/2.0))
	ray.cast_to = Vector3(50.0, 0, 0)
	physics_body_instance.add_child(ray)
	physics_body_instance.add_to_group("tiles")
	if !one_down and mat != disabled_material:
		one_down = true
		if not Engine.editor_hint: mesh_instance.set_destroyed()
	
func check_disabled(var physics_body_instance : StaticBody) -> bool:
	var t_local : Vector3 = physics_body_instance.translation
	var t : Vector3 = physics_body_instance.to_global(t_local)
	var distance_v := Vector2()
	var max_outer : float = TRIPLETS*3*cairo.UNIT*2
	if t.z < 0 or t.x < 0:
		distance_v.x = -min(t.x, t.z)
	if t.z > max_outer or t.x > max_outer:
		distance_v.y = max(t.x, t.z) - max_outer
	var distance = max(distance_v.x, distance_v.y)
	if distance > 0:
		physics_body_instance.visible = false # Used to communicate w below
		if distance > cairo.UNIT*4 and distance > rand.randf_range(0.0, cairo.UNIT*8):
			return true
	return false

func add_cluster(var xOff : int, var yOff : int):
	var spatial : Spatial = Spatial.new()
	var yMod : float = cairo.RIGHT_POINT_Y * xOff
	var xMod : float = cairo.RIGHT_POINT_Y * yOff
	spatial.translate(Vector3(yMod + yOff*(cairo.TOP_POINT_X + cairo.TOP_POINT_Y), 
		0, xOff*(cairo.UNIT + cairo.RIGHT_POINT_X) - xMod))
	var physics_body_a := StaticBody.new() # TL
	var physics_body_b := StaticBody.new() # BL
	var physics_body_c := StaticBody.new() # BR
	var physics_body_d := StaticBody.new() # TR
	physics_body_a.translate(Vector3(cairo.UNIT,0,0))
	physics_body_b.translate(Vector3(cairo.UNIT,0,0))
	physics_body_c.translate(Vector3(cairo.UNIT + cairo.RIGHT_POINT_Y,
		0, cairo.UNIT + cairo.RIGHT_POINT_X))
	physics_body_d.translate(Vector3(cairo.UNIT + cairo.RIGHT_POINT_Y,
		0, cairo.UNIT + cairo.RIGHT_POINT_X))
	physics_body_b.rotate_y(deg2rad(-90.0))
	physics_body_c.rotate_y(deg2rad(180.0))
	physics_body_d.rotate_y(deg2rad(90.0))
	spatial.add_child(physics_body_a)
	spatial.add_child(physics_body_b)
	spatial.add_child(physics_body_c)
	spatial.add_child(physics_body_d)
	add_child(spatial)
	physics_body_a.queue_free() if check_disabled(physics_body_a) else populate(physics_body_a)
	physics_body_b.queue_free() if check_disabled(physics_body_b) else populate(physics_body_b)
	physics_body_c.queue_free() if check_disabled(physics_body_c) else populate(physics_body_c)
	physics_body_d.queue_free() if check_disabled(physics_body_d) else populate(physics_body_d)

# Called when the node enters the scene tree for the first time.
func _ready():
	#disabled_material.flags_unshaded = true
	# Colourful
	#mat_a.albedo_color = Color(204/255.0, 136/255.0, 204/255.0)
	#mat_b.albedo_color = Color(153/255.0, 221/255.0, 187/255.0)
	#mat_c.albedo_color = Color(240/255.0, 28/255.0, 93/255.0)
	#mat_d.albedo_color = Color(30/255.0, 204/255.0, 204/255.0) # R was 136
	# Wood
	#mat_a.albedo_color = Color(60/255.0, 61/255.0, 52/255.0)
	#mat_b.albedo_color = Color(94/255.0, 30/255.0, 18/255.0)
	#mat_c.albedo_color = Color(74/255.0, 43/255.0, 15/255.0)
	#mat_d.albedo_color = Color(181/255.0, 121/255.0, 25/255.0)
	var floor_v := Vector2()
	var border : int = BORDER_TRIPLETS*3
	var arena : int = TRIPLETS*3
	for x in range(-border, (arena*2) + border):
		for y in range(-border - arena, arena + border):
			floor_v = Vector2(floor(x/3.0), floor(y/3.0))
			if (y+border < 0 - floor_v.x  ||  y-border > arena - floor_v.x): continue
			if (x+border < 0 + floor_v.y  ||  x-border > arena + floor_v.y): continue
			add_cluster(x, y)

func _physics_process(var delta):
	set_physics_process(false)
	print("Phys once")
	if Engine.editor_hint:
		return
	for tile in get_tree().get_nodes_in_group("tiles"):
		#print(tile.get_child_count())
		var ray : RayCast = tile.get_child(2)
		for a in range(10):
			ray.force_raycast_update()
			var c = ray.get_collider()
			if c != null and c.get_child(0).has_method("add_neighbour"):
				c.get_child(0).add_neighbour( tile.get_child(0) )
				tile.get_child(0).add_neighbour( c.get_child(0) )
			ray.rotate_object_local(Vector3.UP, 2.0*PI / 10.0)
		ray.queue_free()
	# Can put the starting ones down now that we're done ray casting
	for tile in get_tree().get_nodes_in_group("tiles"):
		var mesh : MeshInstance = tile.get_child(0)
		if mesh.get_state() == TileElement.State.DESTROYED:
			tile.translation.y = -cairo.HEIGHT
