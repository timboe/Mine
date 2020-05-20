extends Spatial

class_name JobManager

const DELAY_PER_ABANDON = 10.0
const DELAY_MAX = 60.0

enum JobType {CONSTRUCT_MONORAIL, CONSTRUCT_BUILDING, REINFORCE, CLAIM_TILE}

var player_jobs : Array
var unassigned_count : Array
var job_id := -1

func _ready():
	for _i in range(GlobalVars.MAX_PLAYERS):
		player_jobs.push_back( {} ) 
		unassigned_count.push_back( 0 )

func add_job(var player : int, var type : int, var place, var target):
	assert(player >= 0 and player < GlobalVars.MAX_PLAYERS)
	var job : Dictionary
	var have_job := false
	var job_dict = player_jobs[player]
	for job in job_dict.values():
		if job["type"] != type:
			continue
		if job["place"] != place:
			continue
		if job["target"] != target:
			continue
		have_job = true
		break
	if have_job:
		return # Already on the books
	#
	job_id += 1
	job = {"id": job_id, "player": player, "type": type, 
		"place": place, "target": target, "assigned": null,
		"abandoned_by": null, "abandoned_n": 0, "abandoned_timer": 0.0}
	unassigned_count[player] += 1
	job_dict[job_id] = job
	print("New job ", job)

func remove_job(var player : int, var id_to_remove : int):
	var job_dict = player_jobs[player]
	assert(job_dict.has(id_to_remove))
	job_dict.erase(id_to_remove)
	
func abandon_job(var player : int, var id_to_remove : int):
	var job_dict = player_jobs[player]
	assert(job_dict.has(id_to_remove))
	var job = job_dict[id_to_remove]
	unassigned_count[player] += 1
	job["abandoned_by"] = job["assigned"]
	job["assigned"] = null
	job["abandoned_n"] += 1
	job["abandoned_timer"] = min(DELAY_MAX, job["abandoned_n"] * DELAY_PER_ABANDON)
	
func try_and_assign(var zoomba, var job_dict : Dictionary) -> bool:
	var closest_job = null
	var zoomba_loc : Vector3 = zoomba.location.pathing_centre
	for job in job_dict.values():
		if job["assigned"] != null:
			continue # Already have a job
		if job["abandoned_timer"] > 0.0:
			continue # Don't reassign this one yet
		var job_loc = job["place"].pathing_centre
		var clostest_job_loc = closest_job["place"].pathing_centre if closest_job != null else null
		if closest_job == null or job_loc.distance_to( zoomba_loc ) < clostest_job_loc.distance_to( zoomba_loc ):
			closest_job = job
	if closest_job != null:
		closest_job["assigned"] = zoomba
		zoomba.assign(closest_job)
		#print("Job " , closest_job["id"], " assigned")
		return true
	return false

func _on_AssignJobs_timeout():
	for player in range(GlobalVars.MAX_PLAYERS):
		if unassigned_count[ player ] == 0:
			continue # No outstanding
		var job_dict : Dictionary = player_jobs[player]
		for job in job_dict.values():
			job["abandoned_timer"] -= $AssignJobs.wait_time
		for zoomba in get_tree().get_nodes_in_group("zoombas"):
			if zoomba.job != null:
				continue # Zoomba already has a job
			if zoomba.player != player:
				continue # Zoomba belongs to another player
			if try_and_assign(zoomba, job_dict):
				unassigned_count[ player ] -= 1
			else:
				 break # no one free
