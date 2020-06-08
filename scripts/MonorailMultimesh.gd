extends MultiMeshInstance

var monorail_dict : Dictionary

func new_mr(var id : int) -> Monorail:
	assert(not monorail_dict.has(id))
	monorail_dict[id] = Monorail.new()
	monorail_dict[id].tween = $Tween
	monorail_dict[id].pathing_manager = $"../PathingManager"
	monorail_dict[id].monorail_mm = multimesh
	monorail_dict[id].monorail_id = id
	return monorail_dict[id]

func _ready():
	var monorial_csg : CSGCombiner = $"../../ObjectFactory/Monoraill/CSGCombiner"
	monorial_csg._update_shape()
	var meshes : Array = monorial_csg.get_meshes()
	var _t : Transform = meshes[0]
	var mesh : Mesh = meshes[1]
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh

