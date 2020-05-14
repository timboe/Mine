tool
extends MeshInstance

var cairo_mesh : ArrayMesh
var cairo_mesh_shape := ConvexPolygonShape.new()

# HEIGHT is vertical height (+y) off of the ground plane (x,z)
# UNIT is the length of the four equal edges of the pentagon
# SMALL_HYPOT is the length of the small edge (S) of the pentagon
# Origin is O
# All internal angles are 90 or 120 deg (120 deg if touching S)
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
const TOP_POINT__RIGHT : float = UNIT * ( 0.5 / tan(deg2rad(30)) )
const TOP_POINT__UP : float = UNIT * 1.5

# RIGHT_POINT is the rightmost vertex of the pentagon (R)
const RIGHT_POINT__RIGHT : float = UNIT * ( 1.0 + (SMALL_HYPOT * sin(deg2rad(30))) )
const RIGHT_POINT__UP : float = UNIT * ( SMALL_HYPOT * cos(deg2rad(30)) )

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
	surface_tool.add_uv(Vector2((TOP_POINT__UP/UNIT)*UV_SCALE, (TOP_POINT__RIGHT/UNIT)*UV_SCALE));
	surface_tool.add_vertex(Vector3(TOP_POINT__UP, HEIGHT, TOP_POINT__RIGHT))
	# 4 Rightmist point, for third triagle
	surface_tool.add_uv(Vector2((RIGHT_POINT__UP/UNIT)*UV_SCALE, (RIGHT_POINT__RIGHT/UNIT)*UV_SCALE));
	surface_tool.add_vertex(Vector3(RIGHT_POINT__UP, HEIGHT, RIGHT_POINT__RIGHT))
	###################################
	# First side (rect 1x2), 5-8
	add_face_vertex(surface_tool, outline_tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, UNIT))
	# Second side (rect sqrt(3)-1x2), 9-12
	add_face_vertex(surface_tool, outline_tool, Vector3(0.0, 0.0, UNIT), Vector3(RIGHT_POINT__UP, 0.0, RIGHT_POINT__RIGHT))
	# Third side (rect 1x2), 13-16
	add_face_vertex(surface_tool, outline_tool, Vector3(RIGHT_POINT__UP, 0.0, RIGHT_POINT__RIGHT), Vector3(TOP_POINT__UP, 0.0, TOP_POINT__RIGHT))
	# Fourth side (rect 1x2), 17-20
	add_face_vertex(surface_tool, outline_tool, Vector3(TOP_POINT__UP, 0.0, TOP_POINT__RIGHT), Vector3(UNIT, 0.0, 0))
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

func _init():
	cairo_mesh = generate_cairo_pentagon()
	cairo_mesh_shape.set_points(cairo_mesh.get_faces())
	mesh = cairo_mesh

