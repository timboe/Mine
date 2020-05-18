extends StaticBody

class_name TileElement

var id := 0

enum State {BUILT, SELECTED, BEING_DESTROYED, DESTROYED, DISABLED}
var state = State.BUILT 
var particles_instance : Particles

var paths : Dictionary # dict of neighbour -> monorail
var neighbours : Array
var mat : SpatialMaterial
var tween : Tween
var camera_manager : Node 
var job_manager : Node 
var player : int # Who owns this floor
var building # What is built here

var monorail_script_resource = load("res://scripts/Monorail.gd")

# Set to a vec3 if this tile is participating in the pathing. Note: in global coordinates
var pathing_centre = null

onready var HEIGHT : float = GlobalVars.FLOOR_HEIGHT + GlobalVars.TILE_OFFSET

const DISABLE_COLOUR : Color = Color(0/255.0, 0/255.0, 0/255.0)
const HOVER_COLOUR : Color = Color(0/255.0, 45/255.0, 227/255.0)
const SELECT_COLOUR : Color = Color(125/255.0, 125/255.0, 0/255.0) # Not used directly
const HOVER_SELECT_COLOUR := HOVER_COLOUR + SELECT_COLOUR
const HOVER_REMOVE_COLOUR : Color = Color(160/255.0, 0/255.0, 56/255.0)
const OWNED_COLOUR : Array = [
	Color(1, 0, 0),
	Color(0, 0, 1),
	Color(1, 1, 0),
	Color(0, 1, 0),
]

const FADE_TIME : float = 5.0

# Only have one countdown timer
var tween_active := false

func set_disabled():
	state = State.DISABLED
	
func set_destroyed():
	state = State.DESTROYED
	mat.emission_energy = 0.0
	
func get_state() -> int:
	return state
	
func set_id(var i: int):
	id = i
	
func get_id():
	return id
	
func links_to(var target : StaticBody, var mr, var my_child : bool):
	assert(neighbours.has(target))
	paths[target] = mr
	if my_child:
		mr.set_connections(self, target)
		target.links_to(self, mr, false) # Add reciprocal link
	
func add_neighbour(var n : StaticBody):
	if !neighbours.has(n):
		neighbours.append(n)

func any_neighbour_destroyed() -> bool:
	for n in neighbours:
		if n.state == State.DESTROYED:
			return true
	return false
	
func _ready():
	player = -1
	building = null
	# See delayed_ready
	
func delayed_ready():
	if state >= State.DISABLED:
		return
	connect("mouse_entered", self, "_on_StaticBody_mouse_entered")
	connect("mouse_exited", self, "_on_StaticBody_mouse_exited")
	connect("input_event", self, "_on_StaticBody_input_event")
	tween = $"../../../Tween"
	camera_manager = $"../../../../CameraManager"
	job_manager = $"../../../../JobManager"
	mat = get_child(0).get_surface_material(0)
	mat.emission_energy = 1.0 
	mat.emission_enabled = false

func update_HOVER_color(var is_hover : bool):
	if state >= State.SELECTED:
		return
	if is_hover:
		mat.emission = HOVER_COLOUR
		mat.emission_enabled = true
	else:
		mat.emission_enabled = false
		
func update_selected():
	if state >= State.BEING_DESTROYED:
		return
	state = State.SELECTED if GlobalVars.SELECTING_MODE else State.BUILT
	tween.remove(self.mat)
	tween.remove(self)
	tween_active = false
	if state == State.SELECTED:
		if any_neighbour_destroyed():
			do_deconstruct_start(FADE_TIME)
		else:
			mat.emission = HOVER_SELECT_COLOUR
	else:
		update_HOVER_color(true)
		
# Called when one of MY neighbors is destroyed. Check if I was queued for destruction
func a_neighbour_just_fell():
	if state == State.SELECTED:
		do_deconstruct_start(FADE_TIME / 5.0)
		
func assign_monorail_jobs_on_demolish():
	# Check for monorail construction tasks
	# Call if I was just destroyed, and there is an owned tile next door
	# Here the owner of the neighbouring tile(s) sets who the jobs go to
	for n in neighbours:
		if n.state != State.DESTROYED:
			continue # No - can only connect to destroyed tiles
		if n.player == -1:
			continue # No - can't setup jobs from unowned tiles to unowned tiles
		job_manager.add_job(n.player, job_manager.JobType.CONSTRUCT_MONORAIL, n, self, "ExtendOntoDemolished")
			
func try_and_spread_monorail():
	# Check for monorail construction tasks
	# Call if a piece of monorail was just finished to/from me
	# Here my owner determins who the jobs go to
	for n in neighbours:
		if n.state != State.DESTROYED:
			continue # No - can only connect to destroyed tiles
		if building != null:
			continue # No - cannot come here to build if there is already a building on this tile
		var mr = paths[n]
		if mr.state == monorail_script_resource.State.CONSTRUCTED:
			continue # No - this link alreadt exists (might be the one we juuust built)
		job_manager.add_job(player, job_manager.JobType.CONSTRUCT_MONORAIL, self, n, "SpreadMonorail")
		
func update_owner_emission():
	if player == -1:
		mat.emission_enabled = false
		return
	var new_e : float = 0.02 
	mat.emission_enabled = true
	mat.emission = OWNED_COLOUR[player]
	for n in neighbours:
		if n.player == player:
			new_e += 0.02
	tween.remove(self.mat)
	tween.interpolate_property(self.mat, "emission_energy", null, new_e, 1.0)
	tween.start()

func do_deconstruct_start(var time : float):
	if tween_active:
		return
	print("Do Tween ", time)
	tween.interpolate_property(self.mat, "emission",
		HOVER_SELECT_COLOUR, HOVER_REMOVE_COLOUR, time,
		Tween.TRANS_CIRC, Tween.EASE_IN)
	tween.interpolate_callback(self, time, "do_deconstruct_a")
	tween.start()
	tween_active = true
	
func do_deconstruct_a():
	print("Remove " + str(id))
	state = State.BEING_DESTROYED
	var thunk_distance : float = GlobalVars.rand.randf_range(0.05, 0.2)
	var thunk_time := thunk_distance * 2
	tween.interpolate_property(self, "translation:y",
		null, -HEIGHT * thunk_distance, thunk_time,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_property(self.mat, "emission_energy",
		1.0, 0.0, thunk_time,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_callback(self, thunk_time, "do_deconstruct_b")
	tween.start()
	
func do_deconstruct_b():
	mat.emission_enabled = false
	var fall_time : float = GlobalVars.rand.randf_range(4.5, 5.5)
	camera_manager.slow_mo(true)
	camera_manager.add_trauma(0.20, to_global(Vector3.ZERO), fall_time)
	tween.interpolate_property(self, "translation:y",
		null, -HEIGHT, fall_time,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_callback(self, fall_time, "done_deconstruct")
	tween.interpolate_callback(camera_manager, 0.25, "slow_mo", false)
	tween.start()
	particles_instance = $"../../../Particles".duplicate()
	self.add_child(particles_instance)
	particles_instance.emitting = true

func done_deconstruct():
	print("Removed " + str(id))
	state = State.DESTROYED
	for n in neighbours:
		n.a_neighbour_just_fell()
	assign_monorail_jobs_on_demolish()
	particles_instance.queue_free()

func _on_StaticBody_mouse_entered():
	update_HOVER_color(true)
	GlobalVars.SELECTED_NODE = self
	if Input.is_mouse_button_pressed(1):
		update_selected()

func _on_StaticBody_mouse_exited():
	update_HOVER_color(false)

func _on_StaticBody_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		print("Me ", get_id(), " " , self)
		for n in neighbours:
			print(" N ", n.get_id() , " " , n.state , " " , n)
		for thePath in paths.keys():
			print (" Path -> ", thePath.get_id())
		GlobalVars.SELECTING_MODE = (state == State.BUILT)
		update_selected()
