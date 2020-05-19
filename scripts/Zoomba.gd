extends Spatial

class_name Zoomba

enum State {IDLE, PATHING, WORKING}

onready var state : int = State.IDLE

const MOVE_TIME := 1.0

var job
var player : int
var location : TileElement
var previous_location : TileElement
var path : PoolIntArray = []
var progress : int

# Used for rotation
var quat_from : Quat
var quat_to : Quat

var mr_class = load("res://scripts/Monorail.gd")

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
	
func pathing_callback():
	assert(state == State.PATHING)
	if location.get_id() == job["place"].get_id():
		start_work()
		return
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
		move(target, "pathing_callback")

func start_work():
	assert(state == State.PATHING)
	state = State.WORKING
	if job["type"] == JobManager.JobType.CONSTRUCT_MONORAIL:
		# Get the monorail segment which connects this tile to the target
		var mr = job["place"].paths[ job["target"] ]
		if mr.state == mr_class.State.INITIAL:
			mr.start_construction(self)
		else: # Job was already done (both directions can get queued, or another team might make the claim)
			print("Monorail construction job was already completed")
			job_finished()

func job_finished():
	assert(state == State.WORKING)
	assert(job != null)
	state = State.IDLE
	var job_id = job["id"]
	job = null
	$"../../../JobManager".remove_job(player, job_id)
	$"../../../JobManager"._on_AssignJobs_timeout()
	idle_callback()
	
func idle_callback():
	if job != null:
		path.resize(0)
		pathing_callback()
		return
	# Get possible ways out of this tile
	var possible_destinations : Array
	for to_test in location.paths.keys():
		var mr = location.paths[to_test]
		if mr.get_passable(player, location, to_test):
			possible_destinations.push_back(to_test)
	# Avoid backtracking, if possible
	var backtrack = possible_destinations.find(previous_location)
	if possible_destinations.size() > 1 and backtrack != -1:
		possible_destinations.remove( backtrack )
	# Remember current tile, for the next backtrack check
	previous_location = location
	# Assign new location if available

	if possible_destinations.size() > 0:
		location = possible_destinations[ GlobalVars.rand.randi() % possible_destinations.size() ]

	# Go to new location. In extreme cases may be the same tile (possible_destinations.size() == 0)
	move(location.pathing_centre, "idle_callback")
	print("Zoomba idle ", previous_location.get_id(), " to " , location.get_id(), " possible dests " , possible_destinations.size())
	
func move(var to, var callback):
	quat_from = Quat(transform.basis)
	look_at(location.pathing_centre, Vector3.UP)
	quat_to = Quat(transform.basis)
	var tween : Tween = $"../../Tween"
	tween.interpolate_method(self, "quat_transform", 0.0, 1.0, MOVE_TIME/2.0)
	tween.interpolate_property(self, "translation", null, location.pathing_centre, MOVE_TIME)
	tween.interpolate_callback(self, MOVE_TIME, callback)
	tween.start()
	

func quat_transform(var amount : float):
	var mid = quat_from.slerp(quat_to, amount)
	transform.basis = Basis(mid)
