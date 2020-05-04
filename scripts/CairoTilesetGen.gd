tool
extends Spatial
class_name CairoTilesetGen

onready var base_material : SpatialMaterial = preload("res://materials/aluminium.tres")
onready var outline_material : ShaderMaterial = preload("res://materials/grid_edges.tres")
onready var disabled_material : ShaderMaterial = preload("res://materials/grid_faces.tres")

var rand := RandomNumberGenerator.new()

var cairo_mesh : ArrayMesh
var cairo_mesh_shape := ConvexPolygonShape.new()

onready var tile_script = preload("res://scripts/TileElement.gd")
var tileID : int = 0

const TRIPLETS : int = 5
const BORDER_TRIPLETS : int = 2

# HEIGHT is vertical height (+y) off of the ground plane (x,z)
# UNIT is the length of the four equal edges of the pentagon
# SMALL_HYPOT is the length of the small edge (S) of the pentagon
# Origin is O
# All internal angles are 90 or 120 deg
#     T
#     /\
#  1 /  \ 1
#   /    \
#   |     / R
# 1 |    / S
#   |___/ 
#  O  1
const HEIGHT : float = 20.0
const UNIT : float = 10.0
const SMALL_HYPOT : float = sqrt(3) - 1

# TOP_POINT is the uppermost vertex of the pentagon (T)
const TOP_POINT_X : float = UNIT * ( 0.5 / tan(deg2rad(30)) )
const TOP_POINT_Y : float = UNIT * 1.5

# RIGHT_POINT is the rightmost vertex of the pentagon (R)
const RIGHT_POINT_X : float = UNIT * ( 1.0 + (SMALL_HYPOT * sin(deg2rad(30))) )
const RIGHT_POINT_Y : float = UNIT * ( SMALL_HYPOT * cos(deg2rad(30)) )

# With UNIT=10 and HEIGHT=20, set to 1 to have textures repete once
# or 0.5 to not repete
const UV_SCALE : float = 0.5
const UV_MAX_HEIGHT = (HEIGHT/UNIT)*UV_SCALE

func add_face(var surface_tool : SurfaceTool, var start : int):
	surface_tool.add_index(start + 0)
	surface_tool.add_index(start + 1)
	surface_tool.add_index(start + 2)
	#
	surface_tool.add_index(start + 1)
	surface_tool.add_index(start + 3)
	surface_tool.add_index(start + 2)
	
func add_face_vertex(var surface_tool : SurfaceTool, var outline_tool : SurfaceTool, var from : Vector3, var to : Vector3):
	## Add the four points needed to draw the two triangles of a rectangle face
	surface_tool.add_uv(Vector2(0.0, 0.0));
	surface_tool.add_vertex(from)
	#
	surface_tool.add_uv(Vector2(0.0, UV_MAX_HEIGHT));
	surface_tool.add_vertex(Vector3(from.x, HEIGHT, from.z))
	#
	surface_tool.add_uv(Vector2(UV_SCALE, 0.0));
	surface_tool.add_vertex(Vector3(to))
	#
	surface_tool.add_uv(Vector2(UV_SCALE, UV_MAX_HEIGHT));
	surface_tool.add_vertex(Vector3(to.x, HEIGHT, to.z))
	## Add the three line segments needed to outline the face
	outline_tool.add_vertex(from)
	outline_tool.add_vertex(Vector3(from.x, HEIGHT, from.z))
	#
	outline_tool.add_vertex(Vector3(from.x, HEIGHT, from.z))
	outline_tool.add_vertex(Vector3(to.x, HEIGHT, to.z))
	#
	outline_tool.add_vertex(from)
	outline_tool.add_vertex(to)
	
func generate_cairo_pentagon() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	var outline_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	outline_tool.begin(Mesh.PRIMITIVE_LINES)
	outline_tool.add_color(Color.cyan)
	###################################
	# Top face, first triangle
	# 0
	surface_tool.add_uv(Vector2(0.0, 0.0));
	surface_tool.add_vertex(Vector3(0.0, HEIGHT, 0.0))
	# 1
	surface_tool.add_uv(Vector2(1.0*UV_SCALE, 0.0));
	surface_tool.add_vertex(Vector3(UNIT, HEIGHT, 0.0))
	# 2
	surface_tool.add_uv(Vector2(0.0, 1.0*UV_SCALE));
	surface_tool.add_vertex(Vector3(0.0, HEIGHT, UNIT))
	# 3 Uppermost point, for second trangle
	surface_tool.add_uv(Vector2((TOP_POINT_Y/UNIT)*UV_SCALE, (TOP_POINT_X/UNIT)*UV_SCALE));
	surface_tool.add_vertex(Vector3(TOP_POINT_Y, HEIGHT, TOP_POINT_X))
	# 4 Rightmist point, for third triagle
	surface_tool.add_uv(Vector2((RIGHT_POINT_Y/UNIT)*UV_SCALE, (RIGHT_POINT_X/UNIT)*UV_SCALE));
	surface_tool.add_vertex(Vector3(RIGHT_POINT_Y, HEIGHT, RIGHT_POINT_X))
	###################################
	# First side (rect 1x2), 5-8
	add_face_vertex(surface_tool, outline_tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, UNIT))
	# Second side (rect sqrt(3)-1x2), 9-12
	add_face_vertex(surface_tool, outline_tool, Vector3(0.0, 0.0, UNIT), Vector3(RIGHT_POINT_Y, 0.0, RIGHT_POINT_X))
	# Third side (rect 1x2), 13-16
	add_face_vertex(surface_tool, outline_tool, Vector3(RIGHT_POINT_Y, 0.0, RIGHT_POINT_X), Vector3(TOP_POINT_Y, 0.0, TOP_POINT_X))
	# Fourth side (rect 1x2), 17-20
	add_face_vertex(surface_tool, outline_tool, Vector3(TOP_POINT_Y, 0.0, TOP_POINT_X), Vector3(UNIT, 0.0, 0))
	# Fifth side (rect 1x2), 21-24
	add_face_vertex(surface_tool, outline_tool, Vector3(UNIT, 0.0, 0), Vector3(0.0, 0.0, 0))
	#####################################################
	# Top face, three triangles
	surface_tool.add_index(0)
	surface_tool.add_index(1)
	surface_tool.add_index(2) 
	#
	surface_tool.add_index(2)
	surface_tool.add_index(1) 
	surface_tool.add_index(3)
	#
	surface_tool.add_index(2)
	surface_tool.add_index(3) 
	surface_tool.add_index(4)
	# First side (rect 1x2)
	add_face(surface_tool, 5)
	# Second side (rect sqrt(3)-1x2)
	add_face(surface_tool, 9)
	# Third side (rect 1x2)
	add_face(surface_tool, 13)
	# Fourth side (rect 1x2)
	add_face(surface_tool, 17)
	# Fifth side (rect 1x2)
	add_face(surface_tool, 21)
	#####################################################
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	var array_mesh = surface_tool.commit()
	outline_tool.index()
	outline_tool.commit(array_mesh)
	return array_mesh

func populate(var physics_body_instance : StaticBody):
	var mesh_instance = MeshInstance.new()
	mesh_instance.use_in_baked_light = true
	mesh_instance.set_script(tile_script)
	mesh_instance.set_mesh(cairo_mesh)
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
	cs.set_shape(cairo_mesh_shape)
	physics_body_instance.add_child(cs)

func check_disabled(var physics_body_instance : StaticBody) -> bool:
	var t_local : Vector3 = physics_body_instance.translation
	var t : Vector3 = physics_body_instance.to_global(t_local)
	var distance_v := Vector2()
	var max_outer : float = TRIPLETS*3*UNIT*2
	if t.z < 0 or t.x < 0:
		distance_v.x = -min(t.x, t.z)
	if t.z > max_outer or t.x > max_outer:
		distance_v.y = max(t.x, t.z) - max_outer
	var distance = max(distance_v.x, distance_v.y)
	if distance > 0:
		physics_body_instance.visible = false # Used to communicate w below
		if distance > UNIT*4 and distance > rand.randf_range(0.0, UNIT*8):
			return true
	return false

func add_cluster(var xOff : int, var yOff : int):
	var spatial : Spatial = Spatial.new()
	var yMod : float = RIGHT_POINT_Y * xOff
	var xMod : float = RIGHT_POINT_Y * yOff
	spatial.translate(Vector3(yMod + yOff*(TOP_POINT_X + TOP_POINT_Y), 0, xOff*(UNIT + RIGHT_POINT_X) - xMod))
	var physics_body_a := StaticBody.new() # TL
	var physics_body_b := StaticBody.new() # BL
	var physics_body_c := StaticBody.new() # BR
	var physics_body_d := StaticBody.new() # TR
	physics_body_a.translate(Vector3(UNIT,0,0))
	physics_body_b.translate(Vector3(UNIT,0,0))
	physics_body_c.translate(Vector3(UNIT + RIGHT_POINT_Y, 0, UNIT + RIGHT_POINT_X))
	physics_body_d.translate(Vector3(UNIT + RIGHT_POINT_Y, 0, UNIT + RIGHT_POINT_X))
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
	cairo_mesh = generate_cairo_pentagon()
	cairo_mesh_shape.set_points(cairo_mesh.get_faces())
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
