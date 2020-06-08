extends Reference
class_name Monorail
# warning-ignore-all:return_value_discarded

const CONSTRUCT_TIME := 1.0

enum State {INITIAL, UNDER_CONSTRUCTION, CONSTRUCTED}
enum Pathing {BIDIRECTIONAL, OWNER_TO_TARGET, TARGET_TO_OWNER, NONE}

var state : int = State.INITIAL
var pathing : Array

var tile_owner : TileElement
var tile_target : TileElement

# These references need passing in
var tween : Tween
var pathing_manager : PathingManager
var monorail_mm : MultiMesh
var monorail_id : int

func _init():
	for _i in range(GlobalVars.MAX_PLAYERS):
		pathing.push_back( Pathing.BIDIRECTIONAL )

func set_connections(var o : TileElement, var t : TileElement):
	tile_owner = o
	tile_target = t
	
func get_translation_y() -> float:
	return monorail_mm.get_instance_transform(monorail_id).origin.y

func set_translation_y(var v : float):
	var t : Transform = monorail_mm.get_instance_transform(monorail_id)
	t.origin.y = v
	monorail_mm.set_instance_transform(monorail_id, t)
	
func start_construction(var by_whome):
	assert(state == State.INITIAL)
	state = State.UNDER_CONSTRUCTION

	tween.remove(self)
	tween.interpolate_method(self, "set_translation_y", get_translation_y(), 0.0, CONSTRUCT_TIME)
	tween.interpolate_callback(self, CONSTRUCT_TIME, "set_constructed", by_whome, false)
	tween.start()
	tile_owner.raise_cap(CONSTRUCT_TIME)
	tile_target.raise_cap(CONSTRUCT_TIME)
	
func abandon_construction():
	assert(state == State.UNDER_CONSTRUCTION)
	tween.remove(self)
	tween.interpolate_method(self, "set_translation_y", get_translation_y(), -0.5, CONSTRUCT_TIME)
	tween.interpolate_callback(self, CONSTRUCT_TIME, "set_initial")
	tween.start()	

func set_initial():
	assert(state == State.UNDER_CONSTRUCTION)
	state = State.INITIAL

func set_constructed(var by_whome, var instant : bool):
	if not instant:
		assert(state == State.UNDER_CONSTRUCTION)
	state = State.CONSTRUCTED
	if tile_owner.player == -1:
		tile_owner.player = by_whome.player
	if tile_target.player == -1:
		tile_target.player = by_whome.player
	if tile_owner.building != null or tile_target.building != null:
		update_building_passable()
	else:
		update_pathing()
	tile_owner.update_owner_emission()
	tile_target.update_owner_emission()
	# Can we connect these out further?
	tile_owner.try_and_spread_monorail()
	tile_target.try_and_spread_monorail()
	# Or start a fight?
	tile_owner.try_and_spread_capture()
	tile_target.try_and_spread_capture()
	set_translation_y(0.0)
	if not instant:
		by_whome.job_finished(true)

func update_building_passable():
	if (state != State.CONSTRUCTED):
		return
	var owner_accessible = (tile_owner.building == null) 
	var target_accessible = (tile_target.building == null)
	var pathing_state : int =  Pathing.NONE
	if owner_accessible and target_accessible:
		pathing_state = Pathing.BIDIRECTIONAL
	elif owner_accessible and not target_accessible:
		pathing_state = Pathing.TARGET_TO_OWNER
	elif not owner_accessible and target_accessible:
		pathing_state = Pathing.OWNER_TO_TARGET
	set_passable_for_all(pathing_state)

func set_passable_for_all(var pathing_state):
	for p in range(GlobalVars.MAX_PLAYERS):
		pathing[p] = pathing_state
	update_pathing()

func set_passable(var player : int, var pathing_state):
	pathing[player] = pathing_state
	update_pathing()

func get_passable(var player : int, var from : TileElement, var to : TileElement):
	if (state != State.CONSTRUCTED):
		return false
	assert(from == tile_owner or from == tile_target)
	assert(to == tile_owner or to == tile_target)
	assert(from != to)
	match pathing[player]:
		Pathing.BIDIRECTIONAL:
			return true
		Pathing.NONE:
			return false
		Pathing.OWNER_TO_TARGET:
			return true if from == tile_owner and to == tile_target else false
		Pathing.TARGET_TO_OWNER:
			return true if from == tile_target and to == tile_owner else false

func update_pathing():
	if state != State.CONSTRUCTED:
		return
	for p in range(GlobalVars.MAX_PLAYERS):
		pathing_manager.disconnect_tiles(p, tile_owner, tile_target)
		match pathing[p]:
			Pathing.BIDIRECTIONAL:
				pathing_manager.connect_tiles(p, tile_owner, tile_target, true)
			Pathing.OWNER_TO_TARGET:
				pathing_manager.connect_tiles(p, tile_owner, tile_target, false)
			Pathing.TARGET_TO_OWNER:
				pathing_manager.connect_tiles(p, tile_target, tile_owner, false)
			Pathing.NONE:
				pass

