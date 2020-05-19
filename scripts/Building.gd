tool
extends StaticBody

var player : int
var location : TileElement

var default_mat = preload("res://materials/player0_material.tres")
var updated_mat

var to_rotate : Array
const A_VELOCITY = 100

func _ready():
	if player > 0:
		updated_mat = load("res://materials/player" + str(player) + "_material.tres")
		recursive_set_livery(self)
	if get_name() == "MCP":
		to_rotate.push_back($MCPTop)
		to_rotate.push_back($MCPFaceTop)
		to_rotate.push_back($MCPBottom)
		to_rotate.push_back($MCPFaceBottom)
	else:
		set_process(false)

func _process(delta):
	for tr in to_rotate:
		tr.rotate_object_local(Vector3.UP, delta * A_VELOCITY)

func update_monorail(var is_built : bool):
	for mr in location.paths.values():
		if not is_built:
			mr.set_passable_for_all( Monorail.Pathing.BIDIRECTIONAL )
		else:
			# Only allow to LEAVE the building
			if location == mr.tile_owner:
				mr.set_passable_for_all( Monorail.Pathing.OWNER_TO_TARGET )
			else:
				assert(location == mr.tile_target)
				mr.set_passable_for_all( Monorail.Pathing.TARGET_TO_OWNER )
	

func recursive_set_livery(var node):
	for c in range(node.get_child_count()):
		recursive_set_livery(node.get_child(c))
	var rid = node.get_surface_material(0).get_rid() if node is MeshInstance and node.get_surface_material(0) != null else null
	if rid != null and rid == default_mat.get_rid():
		node.set_surface_material(0, updated_mat)
