extends Spatial

class_name Zoomba

enum State {IDLE, PATHING, WORKING}

onready var state : int = State.IDLE

const MOVE_TIME := 1.0
const QUICK_ROTATE_TIME := 0.2
const SCRAM : int = 10

var job
var player : int
var location : TileElement
var previous_location : TileElement
var path : PoolIntArray = []
var progress : int
var scram_count : int = 0

# Used for rotation
var quat_from : Quat
var quat_to : Quat

var mr_class = load("res://scripts/Monorail.gd")
var cairo_class = load("res://scripts/Cairo.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	job = null
	$Zapper.visible = false

func initialise(var loc : TileElement, var pl : int):
	add_to_group("zoombas")
	location = loc
	player = pl
	global_transform.origin = location.pathing_centre
	var updated_mat = load("res://materials/player" + str(player) + "_material.tres")
	$Body/CSGBody/CSGMesh.material = updated_mat
	
func scram():
	scram_count = SCRAM
	if state != State.IDLE:
		abandon_job()
		
func assign(var new_job : Dictionary):
	assert(job == null)
	assert(state == State.IDLE)
	assert(new_job["player"] == player)
	state = State.PATHING
	job = new_job
	
func pathing_callback():
	# First - check we didn't scram while moving.
	# If we did then we want to redirect to the idle callback
	if scram_count > 0:
		assert(state == State.IDLE)
		return idle_callback()
		return
	# Second check if at destination
	assert(state == State.PATHING)
	if location.get_id() == job["place"].get_id():
		return start_work()
		return
	# Third, run pathing
	var pm = $"../../PathingManager"
	if path.size() == 0:
		path = pm.pathfind(player, location, job["place"])
		#print("player " , player , " from " , location , " to " , job["place"] , " size " , path.size())
		if path.size() < 2:
			# We were unable to path
			return abandon_job()
			return
		progress = 1 # 0 is our starting location
	assert(progress < path.size())
	location = pm.get_tile( path[progress] )
	progress += 1
	move("pathing_callback")

func abandon_job():
	assert(state == State.PATHING or state == State.WORKING)
	assert(job != null)
	match state:
		State.PATHING:
			return abandon_job_while_pathing()
		State.WORKING:
			return abandon_job_while_working()
		
func abandon_job_while_pathing():
	state = State.IDLE
	var id = job["id"]
	job = null
	print("ABANDONING JOB ", id)
	$"../../../JobManager".abandon_job(player, id)
	# Wait for pathing callback
	
func abandon_job_while_working():
	$Zapper.visible = false
	match job["type"]:
		JobManager.JobType.CONSTRUCT_MONORAIL:
			var mr = job["place"].paths[ job["target"] ]
			mr.abandon_construction()
		JobManager.JobType.CLAIM_TILE:
			var tile = job["place"]
			tile.abandon_capture(self)
		_:
			print("UNKNOWN JOB TYPE")
			assert(false)
	state = State.IDLE
	var id = job["id"]
	job = null
	print("ABANDONING JOB ", id)
	$"../../../JobManager".abandon_job(player, id)
	# If we abandoned while we were working - then we were waiting for the end-of
	# job callback which will now never come. Hence we now need to call idle_callback
	idle_callback()
	
func start_work():
	assert(state == State.PATHING)
	state = State.WORKING
	quick_rotate()
	$Zapper.visible = true
	match job["type"]:
		JobManager.JobType.CONSTRUCT_MONORAIL:
			# Get the monorail segment which connects this tile to the target
			$Zapper.cast_to.y = cairo_class.TOP_POINT__RIGHT
			var mr = job["place"].paths[ job["target"] ]
			if mr.state == mr_class.State.INITIAL:
				mr.start_construction(self)
			else: # Job was already done/stared (both directions can get queued, or another team might make the claim)
				print("Monorail construction job was already handled")
				job_finished()
		JobManager.JobType.CLAIM_TILE:
			$Zapper.cast_to.y = cairo_class.TOP_POINT__RIGHT / 2.0
			var tile = job["place"]
			if tile.player != player:
				tile.start_capture(self)
			else: # Job was already done 
				print("Capture job was already completed")
				job_finished()
		_:
			print("UNKNOWN JOB TYPE")
			assert(false)
			
func quick_rotate():
	if job["target"] == null:
		 return
	setup_rotation(job["target"], null)
	var tween : Tween = $"../../Tween"
	tween.interpolate_method(self, "quat_transform", 0.0, 1.0, QUICK_ROTATE_TIME)
	tween.start()

func job_finished():
	assert(state == State.WORKING)
	assert(job != null)
	state = State.IDLE
	$Zapper.visible = false
	var job_id = job["id"]
	job = null
	$"../../../JobManager".remove_job(player, job_id)
	$"../../../JobManager".assign_jobs()
	idle_callback()
	
func idle_callback():
	if job != null:
		assert(scram_count == 0)
		path.resize(0)
		pathing_callback()
		return
		
	# Get possible ways out of this tile
	var possible_destinations : Array
	for to_test in location.paths.keys():
		var mr = location.paths[to_test]
		if mr.get_passable(player, location, to_test):
			possible_destinations.push_back(to_test)
			
	# Special consderations if scraming
	if scram_count > 0:
		scram_count -= 1
		var enemy_tiles := []
		for d in possible_destinations:
			if d.player != player:
				enemy_tiles.push_back( d )
		if possible_destinations.size() - enemy_tiles.size() > 0: # If at lease one way out isn't to enemy land
			for e in enemy_tiles:
				var loc = possible_destinations.find( e )
				possible_destinations.remove( loc )
			
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
	move("idle_callback")
	#print("Zoomba idle ", previous_location.get_id(), " to " , location.get_id(), " possible dests " , possible_destinations.size())

func setup_rotation(var target, var look_at_from_target):
	quat_from = Quat(transform.basis)
	var cache_rot = transform.basis
	if look_at_from_target != null:
		# If final move, look towards where the job is
		var cache_origin = transform.origin
		transform.origin = target.pathing_centre
		look_at(look_at_from_target.pathing_centre, Vector3.UP)
		transform.origin = cache_origin
	else:
		look_at(target.pathing_centre, Vector3.UP)
	rotation.y -= PI/2.0
	quat_to = Quat(transform.basis)
	transform.basis = cache_rot

func move(var callback):
	setup_rotation(location, null if job == null else job["target"])
	var tween : Tween = $"../../Tween"
	var time = MOVE_TIME 
	if scram_count > 0:
		time *=  0.5
	elif state == State.IDLE:
		time *= 2.0 
	# else - pathing, time *= 1.0
	tween.interpolate_method(self, "quat_transform", 0.0, 1.0,time/2.0)
	tween.interpolate_property(self, "translation", null, location.pathing_centre, time)
	tween.interpolate_callback(self, time, callback)
	tween.start()
	

func quat_transform(var amount : float):
	var mid = quat_from.slerp(quat_to, amount)
	transform.basis = Basis(mid)
