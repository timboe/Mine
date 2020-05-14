extends Node

static func add_faces_edges(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var from : int):
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
	
static func add_vertex(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var v3 : Vector3):
	mesh_tool.add_vertex(v3)
	edge_tool.add_vertex(v3)
	
static func add_vertex_alt(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var y : float, var v2 : Vector2):
	add_vertex(mesh_tool, edge_tool, Vector3(v2.x, y, v2.y))

static func add_face(var mesh_tool : SurfaceTool, var edge_tool : SurfaceTool, var height : float,
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
