extends StaticBody

class_name Building

var id : int
var location : TileElement

var default_mat = preload("res://materials/player0_material.tres")
var updated_mat

enum State {BLUEPRINT, UNDER_CONSTRUCTION, CONSTRUCTED, UNDER_DESTRUCTION}
var state : int

const PULSE_INITIAL := 0.1
const SPAWN_TIME : float = 5.0
const CONSTRUCTION_TIME : float = 5.0
const CAPTURE_TIME : float = 10.0
var capture_in_progress = false
var spawn_start_loc : TileElement setget set_spawn_start_loc
var spawn_particles
var zoomba_constructing_me
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
	set_livery()

func update_monorail():
	assert(location != null)
	for mr in location.paths.values():
		mr.update_building_passable()	

func set_livery():
	if location != null and location.player > 0:
		updated_mat = load("res://materials/player" + str(location.player) + "_material.tres")
		recursive_set_livery(self)

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
	tween.interpolate_callback(self, CONSTRUCTION_TIME, "set_constructed_a", by_whome)
	zoomba_constructing_me = by_whome
	tween.start()
	
func abandon_construction():
	assert(state == State.UNDER_CONSTRUCTION)
	var tween : Tween = $"../../Tween"
	tween.remove(self)
	state = State.BLUEPRINT
	zoomba_constructing_me = null

func set_constructed_a(var by_whome):
	assert(state == State.UNDER_CONSTRUCTION)
	assert(my_blueprint != null)
	state = State.CONSTRUCTED
	by_whome.job_finished(true)
	$BuildinConstructedParticles.emitting = true
	var tween : Tween = $"../../Tween"
	tween.interpolate_callback(self, 1.0, "set_constructed_b")
	zoomba_constructing_me = null
	
func set_constructed_b():
	# Now with cloud cover
	set_visible(true)
	my_blueprint.queue_free()

func on_PulseTimer_timeout(var pulse_n : int):
	assert(location != null)
	for n in location.paths.keys():
		n.pulse_start(PULSE_INITIAL, pulse_n)
		
func add_zoomba():
	var zoomba = $"../../../ObjectFactory/Zoomba".duplicate()
	$"../../Actors".add_child(zoomba)
	zoomba.initialise(spawn_start_loc, location.player) # Sets zoomba owner
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
	
func start_capture(var by_whome):
	var tween : Tween = $"../../Tween"
	tween.interpolate_callback(self, CAPTURE_TIME, "set_captured", by_whome)
	tween.start()
	capture_in_progress = true
	
func abandon_capture():
	var tween : Tween = $"../../Tween"
	tween.remove(self)
	capture_in_progress = false

func set_captured(var by_whome):
	location.set_captured(by_whome)
	set_livery()
	capture_in_progress = false
	if zoomba_constructing_me != null:
		zoomba_constructing_me.scram() # If I was being con/de-structed, now I'm not
	if state == State.BLUEPRINT:
		queue_construction_jobs() # I might have been captured before I was constructed
	
func queue_construction_jobs():
	assert(state == State.BLUEPRINT)
	var job_manager = $"../../JobManager"
	var access_tiles = location.get_access_tiles()
	assert(access_tiles.size() > 0)
	for access in access_tiles:
		job_manager.add_job(location.player, job_manager.JobType.CONSTRUCT_BUILDING, access, location)
	
