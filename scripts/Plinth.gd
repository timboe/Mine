extends MeshInstance

const GENERATE = false

var cairo = preload("res://scripts/Cairo.gd")
var helper = preload("res://scripts/MonumentHelper.gd")

func add_plinth(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool):
	var BEZEL := 2.0
	var HEIGHT := 1.0
	var UNIT : float = cairo.UNIT
	var adg := sin(deg2rad(60)) * sqrt(2*BEZEL) 
	var op  := cos(deg2rad(60)) * sqrt(2*BEZEL)
	# Points
	var p1_edge  := Vector2(0,0)
	var p1_inner := Vector2(BEZEL, BEZEL) 
	#
	var p2_edge  := Vector2(0, UNIT)
	var p2_inner := Vector2(adg, UNIT - op) 
	# 
	var p3_edge  := Vector2(cairo.RIGHT_POINT__UP, cairo.RIGHT_POINT__RIGHT)
	var p3_inner := Vector2(p3_edge.x, p3_edge.y - BEZEL) 
	# 
	var p4_edge  := Vector2(cairo.TOP_POINT__UP, cairo.TOP_POINT__RIGHT)
	var p4_inner := Vector2(p4_edge.x - BEZEL, p4_edge.y - BEZEL/4.0) # Fix me...
	# 
	var p5_edge  := Vector2(UNIT, 0)
	var p5_inner := Vector2(UNIT - op, adg)
	
	helper.add_face(mesh_tool, edge_tool, HEIGHT,
		p1_edge, p1_inner, p2_inner, p2_edge)
	helper.add_face(mesh_tool, edge_tool, HEIGHT,
		p2_edge, p2_inner, p3_inner, p3_edge)
	helper.add_face(mesh_tool, edge_tool, HEIGHT,
		p3_edge, p3_inner, p4_inner, p4_edge)
	helper.add_face(mesh_tool, edge_tool, HEIGHT,
		p4_edge, p4_inner, p5_inner, p5_edge)
	helper.add_face(mesh_tool, edge_tool, HEIGHT,
		p5_edge, p5_inner, p1_inner, p1_edge)
		
	# Top
	mesh_tool.add_uv(Vector2(0, 0))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p1_inner)
	mesh_tool.add_uv(Vector2(0, 1))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p3_inner)
	mesh_tool.add_uv(Vector2(1, 1))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p2_inner)

	# Repeated
	mesh_tool.add_uv(Vector2(0, 1))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p4_inner)
	mesh_tool.add_uv(Vector2(1, 1))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p3_inner)
	
	# Repeated
	mesh_tool.add_uv(Vector2(0, 1))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p5_inner)
	mesh_tool.add_uv(Vector2(1, 1))
	helper.add_vertex_alt(mesh_tool, edge_tool, HEIGHT, p4_inner)

func _init():
	if !GENERATE:
		return
	
	var edge_tool = SurfaceTool.new()
	var mesh_tool = SurfaceTool.new()
	edge_tool.begin(Mesh.PRIMITIVE_LINES)
	edge_tool.add_color(Color.cyan)
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := 5
	
	add_plinth(mesh_tool, edge_tool)
	
	# Faces
	for f in range(0, faces*4, 4):
		helper.add_faces_edges(mesh_tool, edge_tool, f)
		
	# Top is three polygons
	
	mesh_tool.add_index(20)
	mesh_tool.add_index(21)
	mesh_tool.add_index(22)
	
	mesh_tool.add_index(20)
	mesh_tool.add_index(23)
	mesh_tool.add_index(24)
	
	mesh_tool.add_index(20)
	mesh_tool.add_index(25)
	mesh_tool.add_index(26)
	
	mesh_tool.generate_normals()
	mesh_tool.generate_tangents()
	var m : ArrayMesh = mesh_tool.commit()
	edge_tool.index()
	edge_tool.commit(m)  
	
	var face_mat = load("res://materials/grid_faces.tres")
	var edge_mat = load("res://materials/grid_edges.tres")
	
	m.surface_set_material(0, face_mat)
	m.surface_set_material(1, edge_mat)
	set_mesh(m)
	#create_convex_collision()
	
