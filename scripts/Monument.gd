extends StaticBody

onready var beacon : MeshInstance = $Beacon
onready var mesh_instance : MeshInstance = $MeshInstance
var cylinder : CylinderMesh 



var time : float = 0

func add_faces_edges(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var from : int):
	mesh_tool.add_index(from)
	mesh_tool.add_index(from + 1)
	mesh_tool.add_index(from + 2)
	#
	mesh_tool.add_index(from)
	mesh_tool.add_index(from + 2)
	mesh_tool.add_index(from + 3)
	##
	edge_tool.add_index(from)
	edge_tool.add_index(from + 1)
	#
	edge_tool.add_index(from + 1)
	edge_tool.add_index(from + 2)
	#
	edge_tool.add_index(from + 2)
	edge_tool.add_index(from + 3)
	#
	edge_tool.add_index(from + 3)
	edge_tool.add_index(from)
	
func add_vertex(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var v3 : Vector3):
	mesh_tool.add_vertex(v3)
	edge_tool.add_vertex(v3)

func add_face(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var height : float,
	var bl : Vector2, var tl : Vector2,
	var tr : Vector2, var br : Vector2):
	
	mesh_tool.add_uv(Vector2(0, 0))
	add_vertex(mesh_tool, edge_tool, Vector3(bl.x, 0, bl.y))
	mesh_tool.add_uv(Vector2(0, 1))
	add_vertex(mesh_tool, edge_tool, Vector3(tl.x, height, tl.y))
	mesh_tool.add_uv(Vector2(1, 1))
	add_vertex(mesh_tool, edge_tool, Vector3(tr.x, height, tr.y))
	mesh_tool.add_uv(Vector2(1, 0))
	add_vertex(mesh_tool, edge_tool, Vector3(br.x, 0, br.y))

func add_monument(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool,
	var LENGTH : float, var HEIGHT : float, var CENTRE : float):
		
	add_face(mesh_tool, edge_tool, HEIGHT,
		Vector2(0,0), Vector2(LENGTH, LENGTH),
		Vector2(LENGTH, LENGTH + CENTRE), Vector2(0, LENGTH + LENGTH + CENTRE))
	
	add_face(mesh_tool, edge_tool, HEIGHT,
		Vector2(0, LENGTH + LENGTH + CENTRE), Vector2(LENGTH, LENGTH + CENTRE),
		Vector2(LENGTH + CENTRE, LENGTH + CENTRE), Vector2(LENGTH + LENGTH + CENTRE, LENGTH + LENGTH + CENTRE))
	
	add_face(mesh_tool, edge_tool, HEIGHT,
		Vector2(LENGTH + LENGTH + CENTRE, LENGTH + LENGTH + CENTRE), Vector2(LENGTH + CENTRE, LENGTH + CENTRE),
		Vector2(LENGTH + CENTRE, LENGTH), Vector2(LENGTH + LENGTH + CENTRE, 0))

	add_face(mesh_tool, edge_tool, HEIGHT,
		Vector2(LENGTH + LENGTH + CENTRE, 0), Vector2(LENGTH + CENTRE, LENGTH),
		Vector2(LENGTH, LENGTH), Vector2(0, 0))
	
	# Top
	mesh_tool.add_uv(Vector2(0, 0))
	add_vertex(mesh_tool, edge_tool, Vector3(LENGTH, HEIGHT, LENGTH))
	mesh_tool.add_uv(Vector2(0, 1))
	add_vertex(mesh_tool, edge_tool, Vector3(LENGTH + CENTRE, HEIGHT, LENGTH ))
	mesh_tool.add_uv(Vector2(1, 1))
	add_vertex(mesh_tool, edge_tool, Vector3(LENGTH + CENTRE, HEIGHT, LENGTH + CENTRE))
	mesh_tool.add_uv(Vector2(1, 0))
	add_vertex(mesh_tool, edge_tool, Vector3(LENGTH, HEIGHT, LENGTH + CENTRE))

func add_plinth(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool):
	pass

func _ready():
	var edge_tool = SurfaceTool.new()
	var mesh_tool = SurfaceTool.new()
	edge_tool.begin(Mesh.PRIMITIVE_LINES)
	edge_tool.add_color(Color.cyan)
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := 4 if "Monument" in get_name() else 5
	
	if faces == 4:
		var LENGTH : float = 20.0
		var HEIGHT : float = 20.0
		var CENTRE : float = 10.0
		add_monument(mesh_tool, edge_tool, LENGTH, HEIGHT, CENTRE)
		
		beacon.transform = Transform.IDENTITY
		cylinder = beacon.mesh as CylinderMesh 
		cylinder.height = 2000
		beacon.translate(Vector3(LENGTH + CENTRE/2.0, HEIGHT + cylinder.height/2.0, LENGTH + CENTRE/2.0))
		var particles : Particles = $Particles
		particles.transform = Transform.IDENTITY
		particles.translate(Vector3(LENGTH + CENTRE/2.0, HEIGHT + 100, LENGTH + CENTRE/2.0))
		
	elif faces == 5:
#		add_plinth(mesh_tool, edge_tool)
		return

	# Faces
	for f in range(0, (faces+1)*4, 4):
		add_faces_edges(mesh_tool, edge_tool, f)
	
	mesh_tool.generate_normals()
	mesh_tool.generate_tangents()
	var m : ArrayMesh = mesh_tool.commit()
	edge_tool.index()
	edge_tool.commit(m)  
	
	var face_mat = load("res://materials/grid_faces.tres")
	var edge_mat = load("res://materials/grid_edges.tres")
	
	m.surface_set_material(0, face_mat)
	m.surface_set_material(1, edge_mat)
	mesh_instance.set_mesh(m)
	mesh_instance.create_convex_collision()
	
	
func _process(var delta : float):
	time += delta
	if cylinder:
		cylinder.top_radius = abs(sin(time)) + 0.5
		cylinder.bottom_radius = cylinder.top_radius
