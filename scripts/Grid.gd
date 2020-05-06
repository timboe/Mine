tool
extends MeshInstance

const LENGTH : float = 100.0
const STEPS : int = 10
const STEP_SIZE : float = LENGTH / STEPS

func _init():
	var surface_tool = SurfaceTool.new()
	var mesh_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	surface_tool.add_color(Color.cyan)
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step_x in range(STEPS):
		for step_y in range(STEPS):
			surface_tool.add_vertex(Vector3((step_x+0) * STEP_SIZE, 0.0, step_y * STEP_SIZE))
			surface_tool.add_vertex(Vector3((step_x+1) * STEP_SIZE, 0.0, step_y * STEP_SIZE))
			#
			surface_tool.add_vertex(Vector3(step_x * STEP_SIZE, 0.0, (step_y+0) * STEP_SIZE))
			surface_tool.add_vertex(Vector3(step_x * STEP_SIZE, 0.0, (step_y+1) * STEP_SIZE))
			##
			mesh_tool.add_uv(Vector2(0.0, 0.0))
			mesh_tool.add_vertex(Vector3((step_x+0) * STEP_SIZE, 0.0, (step_y+0) * STEP_SIZE))
			mesh_tool.add_uv(Vector2(0.0, 1.0))
			mesh_tool.add_vertex(Vector3((step_x+1) * STEP_SIZE, 0.0, (step_y+0) * STEP_SIZE))
			mesh_tool.add_uv(Vector2(1.0, 0.0))
			mesh_tool.add_vertex(Vector3((step_x+0) * STEP_SIZE, 0.0, (step_y+1) * STEP_SIZE))
			#
			mesh_tool.add_uv(Vector2(0.0, 1.0))
			mesh_tool.add_vertex(Vector3((step_x+1) * STEP_SIZE, 0.0, (step_y+0) * STEP_SIZE))
			mesh_tool.add_uv(Vector2(1.0, 1.0))
			mesh_tool.add_vertex(Vector3((step_x+1) * STEP_SIZE, 0.0, (step_y+1) * STEP_SIZE))
			mesh_tool.add_uv(Vector2(1.0, 0.0))
			mesh_tool.add_vertex(Vector3((step_x+0) * STEP_SIZE, 0.0, (step_y+1) * STEP_SIZE))
	surface_tool.index()
	mesh_tool.index()
	mesh_tool.generate_normals()
	mesh_tool.generate_tangents()
	var m : ArrayMesh = mesh_tool.commit()
	surface_tool.commit(m)  
	set_mesh(m)

