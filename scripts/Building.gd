extends StaticBody

var player : int
var location : TileElement

var default_mat = preload("res://materials/player0_material.tres")
var updated_mat

var to_rotate : Array
const A_VELOCITY = 100
const PULSE_INITIAL := 0.1
const TRANSITION_TIME : float = 5.0
var pulse_n := 0
var spawn_start_loc : TileElement setget set_spawn_start_loc
var spawn_particles

func set_spawn_start_loc(var s):
	spawn_start_loc = s
	spawn_particles = $"../../../CameraManager/SpawnParticles".duplicate()
	$"../".add_child(spawn_particles)
	spawn_particles.transform.origin = spawn_start_loc.pathing_centre
	
func _ready():
	if player > 0:
		updated_mat = load("res://materials/player" + str(player) + "_material.tres")
		recursive_set_livery(self)
	#
	if get_name() == "MCP":
		to_rotate.push_back($MCPTop)
		to_rotate.push_back($MCPFaceTop)
		to_rotate.push_back($MCPBottom)
		to_rotate.push_back($MCPFaceBottom)
	else:
		set_process(false)
	#


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


func on_PulseTimer_timeout():
	if location == null:
		print("loc == null, ",self)
		return
	print("pulse ", pulse_n)
	pulse_n += 1
	for n in location.paths.keys():
		n.pulse_start(PULSE_INITIAL, pulse_n)
		
func add_zoomba():
	var zoomba = $"../../../ObjectFactory/Zoomba".duplicate()
	$"../../Actors".add_child(zoomba)
	zoomba.initialise(spawn_start_loc, player) # Sets zoomba owner
	var tween : Tween = $"../../Tween"
	tween.interpolate_property(zoomba, "translation:y", 
		zoomba.translation.y - 2, zoomba.translation.y, TRANSITION_TIME)
	tween.interpolate_callback(self, TRANSITION_TIME, "zoomba_callback", zoomba)
	tween.start()
	spawn_particles.emitting = true
	return zoomba
#
func zoomba_callback(var z):
	spawn_particles.emitting = false
	z.idle_callback()
	
