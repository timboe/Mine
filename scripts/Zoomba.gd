extends Spatial
class_name Zoomba
# warning-ignore-all:return_value_discarded

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

onready var tween : Tween = $"../Tween"
onready var job_manager : JobManager = $"../../JobManager"
onready var pathing_manager : Node = $"../../CairoTilesetGen/PathingManager"
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
		abandon_job(true)
		
func assign(var new_job : Dictionary):
	assert(job == null)
	assert(state == State.IDLE)
	assert(new_job["player"] == player)
	state = State.PATHING
	job = new_job

func check_pathing_valid() -> bool:
	if path.size() == 0:
		path = pathing_manager.pathfind(player, location, job["place"])
		progress = 1 # 0 is our starting location
		#print("player " , player , " from " , location , " to " , job["place"] , " size " , path.size())
		if path.size() < 2:
			return false # We were unable to path
	return true

func pathing_callback():
	# First - check we didn't scram while moving.
	# If we did then we want to redirect to the idle callback
	if scram_count > 0:
		assert(state == State.IDLE)
		return idle_callback()
	assert(state == State.PATHING)
	# Second - check our job is stil valid
	if not check_job_still_valid():
		return job_finished(false)
	# Third check if at destination
	if location.get_id() == job["place"].get_id():
		return start_work()
	# Fourth, run pathing
	if not check_pathing_valid():
		return abandon_job(false) # No active call-backs
	# Fifth, move to next location
	assert(progress < path.size())
	location = pathing_manager.get_tile( path[progress] )
	progress += 1
	move("pathing_callback")

func abandon_job(var have_active_callback : bool = true):
	assert(state == State.PATHING or state == State.WORKING)
	assert(job != null)
	match state:
		State.PATHING:
			return abandon_job_while_pathing(have_active_callback)
		State.WORKING:
			return abandon_job_while_working(have_active_callback)
		
func abandon_job_while_pathing(var have_active_callback : bool):
	state = State.IDLE
	var id = job["id"]
	print("ABANDONING JOB WHILE PATHING ", job)
	job = null
	job_manager.abandon_job(player, id)
	# Wait for pathing callback, unless it was the pathing itself which failed
	if not have_active_callback:
		idle_callback()
		
func abandon_job_while_working(var have_active_callback : bool):
	assert(have_active_callback == true)
	$Zapper.visible = false
	match job["type"]:
		JobManager.JobType.CONSTRUCT_MONORAIL:
			var mr = job["place"].paths[ job["target"] ]
			mr.abandon_construction()
		JobManager.JobType.CONSTRUCT_BUILDING:
			var building = job["target"].building
			building.abandon_construction()
		JobManager.JobType.CLAIM_TILE:
			var tile = job["place"]
			tile.abandon_capture(self)
		JobManager.JobType.CLAIM_BUILDING:
			var building = job["target"].building
			building.abandon_capture()
		_:
			print("UNKNOWN JOB TYPE")
			assert(false)
	state = State.IDLE
	var id = job["id"]
	print("ABANDONING JOB WHILE WORKIN ", id)
	job = null
	job_manager.abandon_job(player, id)
	# If we abandoned while we were working - then we were waiting for the end-of
	# job callback which will now never come. Hence we now need to call idle_callback
	idle_callback()

func check_job_still_valid() -> bool:
	match job["type"]:
		JobManager.JobType.CONSTRUCT_MONORAIL:
			# Get the monorail segment which connects this tile to the target
			var mr = job["place"].paths[ job["target"] ]
			if mr.state != mr_class.State.INITIAL:
				return false  # Job was already done/stared (both directions can get queued, or another team might make the claim)
		JobManager.JobType.CONSTRUCT_BUILDING:
			var building = job["target"].building
			if building == null:
				# Expect rare
				print("Building == null for CONSTRUCT_BUILDING job? ", job)
				return false
			if building.state != building.State.BLUEPRINT:
				return false # Job was already done/stared (many directions can get queued)
			if building.location.player != player:
				return false # Was taken
		JobManager.JobType.CLAIM_TILE:
			var tile = job["place"]
			if tile.player == player: 
				return false # Already (re)/claimed
			if tile.building != null:
				return false # Should now be a claim building job
		JobManager.JobType.CLAIM_BUILDING:
			var building = job["target"].building
			if building == null:
				return false # Nothing left to claim
			if job["place"].player != player:
				return false # No longer own this adjacent tile
			if building.location.player == player:
				return false # Already captured
			if building.capture_in_progress:
				return false # Already being captured
		_:
			print("UNKNOWN JOB TYPE")
			assert(false)
	return true
	
func start_work():
	assert(state == State.PATHING)
	state = State.WORKING
	quick_rotate()
	$Zapper.visible = true
	match job["type"]:
		JobManager.JobType.CONSTRUCT_MONORAIL:
			# Get the monorail segment which connects this tile to the target
			$Zapper.cast_to.y = cairo_class.UNIT
			var mr = job["place"].paths[ job["target"] ]
			assert(mr.state == mr_class.State.INITIAL)
			mr.start_construction(self)
		JobManager.JobType.CONSTRUCT_BUILDING:
			$Zapper.cast_to.y = cairo_class.UNIT
			var building = job["target"].building
			assert(building != null)
			building.start_construction(self)
		JobManager.JobType.CLAIM_TILE:
			$Zapper.cast_to.y = cairo_class.UNIT / 2.0
			var tile = job["place"]
			assert(tile.player != player)
			tile.start_capture(self)
		JobManager.JobType.CLAIM_BUILDING:
			$Zapper.cast_to.y = cairo_class.UNIT
			var building = job["target"].building
			assert(building != null)
			assert(job["place"].player == player)
			building.start_capture(self)
		_:
			print("UNKNOWN JOB TYPE")
			assert(false)
			
func quick_rotate():
	if job["target"] == null:
		 return
	setup_rotation(job["target"], null)
	tween.interpolate_method(self, "quat_transform", 0.0, 1.0, QUICK_ROTATE_TIME)
	tween.start()

func job_finished(var work_was_done : bool):
	assert((work_was_done and state == State.WORKING) or (not work_was_done and state == State.PATHING))
	assert(job != null)
	state = State.IDLE
	$Zapper.visible = false
	var job_id = job["id"]
	job = null
	job_manager.remove_job(player, job_id)
	job_manager.assign_jobs()
	idle_callback()
	
func idle_callback():
	if job != null:
		assert(scram_count == 0)
		path.resize(0)
		pathing_callback()
		return
		
	# Get possible ways out of this tile
	var possible_destinations := []
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
		# Note: Sometimes, if stuck, we path to our own tile
		#if transform.origin.distance_to( location.pathing_centre ) > 1e-3:
		look_at(target.pathing_centre, Vector3.UP)
	rotation.y -= PI/2.0
	quat_to = Quat(transform.basis)
	transform.basis = cache_rot

func move(var callback):
	setup_rotation(location, null if job == null else job["target"])
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
