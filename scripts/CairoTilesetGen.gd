tool
extends Spatial
class_name CairoTilesetGen

onready var base_material = preload("res://test_materials/aluminium.tres")
var mat_a : Material = null
var mat_b : Material = null
var mat_c : Material = null
var mat_d : Material = null

var cairo_mesh : ArrayMesh
var cairo_mesh_shape := ConvexPolygonShape.new()

onready var tile_script = preload("res://scripts/TileElement.gd")
var tileID : int = 0

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
	
func add_face_vertex(var surface_tool : SurfaceTool, var from : Vector3, var to : Vector3):
	surface_tool.add_uv(Vector2(0.0, 0.0));
	surface_tool.add_vertex(from)
	# 6
	surface_tool.add_uv(Vector2(0.0, UV_MAX_HEIGHT));
	surface_tool.add_vertex(Vector3(from.x, HEIGHT, from.z))
	# 7
	surface_tool.add_uv(Vector2(UV_SCALE, 0.0));
	surface_tool.add_vertex(Vector3(to))
	# 8
	surface_tool.add_uv(Vector2(UV_SCALE, UV_MAX_HEIGHT));
	surface_tool.add_vertex(Vector3(to.x, HEIGHT, to.z))
	
	
func generate_cairo_pentagon() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
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
	add_face_vertex(surface_tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, UNIT))
	# Second side (rect sqrt(3)-1x2), 9-12
	add_face_vertex(surface_tool, Vector3(0.0, 0.0, UNIT), Vector3(RIGHT_POINT_Y, 0.0, RIGHT_POINT_X))
	# Third side (rect 1x2), 13-16
	add_face_vertex(surface_tool, Vector3(RIGHT_POINT_Y, 0.0, RIGHT_POINT_X), Vector3(TOP_POINT_Y, 0.0, TOP_POINT_X))
	# Fourth side (rect 1x2), 17-20
	add_face_vertex(surface_tool, Vector3(TOP_POINT_Y, 0.0, TOP_POINT_X), Vector3(UNIT, 0.0, 0))
	# Fifth side (rect 1x2), 21-24
	add_face_vertex(surface_tool, Vector3(UNIT, 0.0, 0), Vector3(0.0, 0.0, 0))
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
	return surface_tool.commit()

func new_physics_body(var mat : Material) -> StaticBody:
	var physics_body_instance = StaticBody.new()
	var mesh_instance = MeshInstance.new()
	mesh_instance.use_in_baked_light = true
	mesh_instance.set_script(tile_script)
	mesh_instance.set_mesh(cairo_mesh)
	mesh_instance.set_surface_material(0, mat.duplicate())
	if not Engine.editor_hint:
		mesh_instance.setID(tileID)
	tileID += 1
	physics_body_instance.add_child(mesh_instance)
	var cs = CollisionShape.new()
	cs.set_shape(cairo_mesh_shape)
	physics_body_instance.add_child(cs)
	return physics_body_instance

func addCluster(var xOff : int, var yOff : int):
	var spatial : Spatial = Spatial.new()
	var yMod : float = RIGHT_POINT_Y * xOff
	var xMod : float = RIGHT_POINT_Y * yOff
	spatial.translate(Vector3(yMod + yOff*(TOP_POINT_X + TOP_POINT_Y), 0, xOff*(UNIT + RIGHT_POINT_X) - xMod))
	var physics_body_a : StaticBody = new_physics_body(mat_a) # TL
	var physics_body_b : StaticBody = new_physics_body(mat_b) # BL
	var physics_body_c : StaticBody = new_physics_body(mat_c) # BR
	var physics_body_d : StaticBody = new_physics_body(mat_d) # TR
	#
	physics_body_a.translate(Vector3(UNIT,0,0))
	spatial.add_child(physics_body_a)
	#
	physics_body_b.translate(Vector3(UNIT,0,0))
	physics_body_b.rotate_y(deg2rad(-90.0))
	spatial.add_child(physics_body_b)
	#
	physics_body_c.translate(Vector3(UNIT + RIGHT_POINT_Y, 0, UNIT + RIGHT_POINT_X))
	physics_body_c.rotate_y(deg2rad(180.0))
	spatial.add_child(physics_body_c)
	#
	physics_body_d.translate(Vector3(UNIT + RIGHT_POINT_Y, 0, UNIT + RIGHT_POINT_X))
	physics_body_d.rotate_y(deg2rad(90.0))
	spatial.add_child(physics_body_d)
	add_child(spatial)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	cairo_mesh = generate_cairo_pentagon()
	cairo_mesh_shape.set_points(cairo_mesh.get_faces())
	mat_a = base_material.duplicate()
	mat_b = base_material.duplicate()
	mat_c = base_material.duplicate()
	mat_d = base_material.duplicate()
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
	var triplets: int = 5
	var floor_v : Vector2 = Vector2()
	for x in range(0, triplets*6):
		for y in range(-triplets*3, triplets*3):
			floor_v = Vector2(floor(x/3.0), floor(y/3.0))
			if (y < 0 - floor_v.x  ||  y > triplets*3 - floor_v.x): continue
			if (x < 0 + floor_v.y  ||  x > triplets*3 + floor_v.y): continue
			addCluster(x, y)
