extends Spatial

class_name JobManager

enum JobType {CONSTRUCT_MONORAIL, CONSTRUCT_BUILDING, REINFORCE}

var player_jobs : Array
var unassigned_count : Array
var job_id := -1

func _ready():
	for _i in range(GlobalVars.MAX_PLAYERS):
		player_jobs.push_back( {} ) 
		unassigned_count.push_back( 0 )

func add_job(var player : int, var type : int, var place, var target, var what : String):
	assert(player >= 0 and player < GlobalVars.MAX_PLAYERS)
	var job : Dictionary
	var have_job := false
	var job_dict = player_jobs[player]
	for job in job_dict.values():
		if job["type"] != type:
			continue
		if (job["place"] == place and job["target"] == target) or (job["place"] == target and job["target"] == place):
			have_job = true
			break
	if have_job:
		return # Already on the books
	#
	job_id += 1
	job = {"id": job_id, "player": player, "type": type, 
		"place": place, "target": target, "assigned": null,
		"what": what}
	unassigned_count[player] += 1
	job_dict[job_id] = job
	print("New job ", job)

func remove_job(var player : int, var id_to_remove : int):
	var job_dict = player_jobs[player]
	assert(job_dict.has(id_to_remove))
	job_dict.erase(id_to_remove)

func try_and_assign(var zoomba, var job_dict : Dictionary) -> bool:
	var closest_job = null
	var zoomba_loc : Vector3 = zoomba.location.pathing_centre
	for job in job_dict.values():
		if job["assigned"] != null:
			continue # Already have a job
		var job_loc = job["place"].pathing_centre
		var clostest_job_loc = closest_job["place"].pathing_centre if closest_job != null else null
#		if (job["place"].pathing_centre == null or (closest_job != null and closest_job["place"].pathing_centre == null) or zoomba_location == null):
#				print("STRANGE CRASH DEBUG ", job["place"].pathing_centre, " ", closest_job["place"].pathing_centre, " ", zoomba_location)
		if closest_job == null or job_loc.distance_to( zoomba_loc ) < clostest_job_loc.distance_to( zoomba_loc ):
			closest_job = job
	if closest_job != null:
		closest_job["assigned"] = zoomba
		zoomba.assign(closest_job)
		return true
	return false

func _on_AssignJobs_timeout():
	for player in range(GlobalVars.MAX_PLAYERS):
		if unassigned_count[ player ] == 0:
			continue # No outstanding
		var job_dict : Dictionary = player_jobs[player]
		for zoomba in get_tree().get_nodes_in_group("zoombas"):
			if zoomba.job != null:
				continue # Zoomba already has a job
			if zoomba.player != player:
				continue # Zoomba belongs to another player
			if try_and_assign(zoomba, job_dict):
				unassigned_count[ player ] -= 1
			else:
				 break # no one free
