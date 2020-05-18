extends Spatial

class_name Zoomba

enum State {IDLE, PATHING, WORKING}

onready var state : int = State.IDLE

const MOVE_TIME := 1.0

var job
var player : int
var location : TileElement
var path : PoolIntArray = []
var progress : int

# Called when the node enters the scene tree for the first time.
func _ready():
	job = null
	
func initialise(var loc : TileElement, var pl : int):
	add_to_group("zoombas")
	location = loc
	player = pl
	global_transform.origin = location.pathing_centre

func assign(var new_job : Dictionary):
	assert(job == null)
	assert(state == State.IDLE)
	assert(new_job["player"] == player)
	state = State.PATHING
	job = new_job
	path.resize(0)
	pathing_callback()
	
func pathing_callback():
	assert(state == State.PATHING)
	if location.get_id() == job["place"].get_id():
		start_work()
	else:
		var pm = $"../../PathingManager"
		if path.size() == 0:
			path = pm.pathfind(player, location, job["place"])
			print("player " , player , " from " , location , " to " , job["place"] , " size " , path.size())
			assert(path.size() >= 2)
			progress = 1 # 0 is our starting location
		assert(progress < path.size())
		var target = pm.get_point( path[progress] )
		location = pm.get_tile( path[progress] )
		progress += 1
		var tween : Tween = $"../../Tween"
		tween.interpolate_property(self, "translation", null, target, MOVE_TIME)
		tween.interpolate_callback(self, MOVE_TIME, "pathing_callback")
		tween.start()

func start_work():
	assert(state == State.PATHING)
	state = State.WORKING
	if job["type"] == JobManager.JobType.CONSTRUCT_MONORAIL:
		# Get the monorail segment which connects this tile to the target
		var mr = job["place"].paths[ job["target"] ]
		mr.start_construction(self)

func job_finished():
	assert(state == State.WORKING)
	assert(job != null)
	state = State.IDLE
	var job_id = job["id"]
	job = null
	$"../../../JobManager".remove_job(player, job_id)
	$"../../../JobManager"._on_AssignJobs_timeout()
