extends StaticBody

var player : int
var id : int
var location : TileElement

var default_mat = preload("res://materials/player0_material.tres")
var updated_mat

enum State {BLUEPRINT, UNDER_CONSTRUCTION, CONSTRUCTED, UNDER_DESTRUCTION}
var state : int

var to_rotate : Array
const A_VELOCITY = 100
const PULSE_INITIAL := 0.1
const SPAWN_TIME : float = 5.0
const CONSTRUCTION_TIME : float = 5.0

var spawn_start_loc : TileElement setget set_spawn_start_loc
var spawn_particles
var my_blueprint setget set_blueprint

func set_blueprint(var b):
	my_blueprint = b
	set_visible(false)
	update_monorail()
	state = State.BLUEPRINT

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

func _process(delta):
	for tr in to_rotate:
		tr.rotate_object_local(Vector3.UP, delta * A_VELOCITY)

func update_monorail():
	assert(location != null)
	for mr in location.paths.values():
		mr.update_building_passable()	

func recursive_set_livery(var node):
	for c in range(node.get_child_count()):
		recursive_set_livery(node.get_child(c))
	var rid = node.get_surface_material(0).get_rid() if node is MeshInstance and node.get_surface_material(0) != null else null
	if rid != null and rid == default_mat.get_rid():
		node.set_surface_material(0, updated_mat)


func start_construction(var by_whome):
	assert(state == State.BLUEPRINT)
	state = State.UNDER_CONSTRUCTION
	var tween : Tween = $"../../Tween"
	tween.remove(self)
	tween.interpolate_callback(self, CONSTRUCTION_TIME, "set_constructed", by_whome)
	tween.start()
	
func abandon_construction():
	assert(state == State.UNDER_CONSTRUCTION)
	var tween : Tween = $"../../Tween"
	tween.remove(self)
	state = State.BLUEPRINT

func set_constructed(var by_whome):
	assert(state == State.UNDER_CONSTRUCTION)
	assert(my_blueprint != null)
	state = State.CONSTRUCTED
	set_visible(true)
	my_blueprint.queue_free()
	by_whome.job_finished()

func on_PulseTimer_timeout(var pulse_n : int):
	assert(location != null)
	for n in location.paths.keys():
		n.pulse_start(PULSE_INITIAL, pulse_n)
		
func add_zoomba():
	var zoomba = $"../../../ObjectFactory/Zoomba".duplicate()
	$"../../Actors".add_child(zoomba)
	zoomba.initialise(spawn_start_loc, player) # Sets zoomba owner
	var tween : Tween = $"../../Tween"
	tween.interpolate_property(zoomba, "translation:y", 
		zoomba.translation.y - 2, zoomba.translation.y, SPAWN_TIME)
	tween.interpolate_callback(self, SPAWN_TIME, "zoomba_callback", zoomba)
	tween.start()
	spawn_particles.emitting = true
	return zoomba
#
func zoomba_callback(var z):
	spawn_particles.emitting = false
	z.idle_callback()
	
