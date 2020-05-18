extends StaticBody

class_name Monorail

const CONSTRUCT_TIME := 1.0

enum State {INITIAL, UNDER_CONSTRUCTION, CONSTRUCTED}
enum Pathing {BIDIRECTIONAL, OWNER_TO_TARGET, TARGET_TO_OWNER, NONE}

var state : int = State.INITIAL
var pathing : Array

var tile_owner : TileElement
var tile_target : TileElement

func _ready():
	for _i in range(GlobalVars.MAX_PLAYERS):
		pathing.push_back( Pathing.BIDIRECTIONAL )

func set_connections(var o : TileElement, var t : TileElement):
	tile_owner = o
	tile_target = t
	
func start_construction(var by_whome):
	assert(state == State.INITIAL)
	state = State.UNDER_CONSTRUCTION
	var tween : Tween = $"../../Tween"
	tween.interpolate_property(self, "translation:y", null, 0.0, CONSTRUCT_TIME)
	tween.interpolate_callback(self, CONSTRUCT_TIME, "set_constructed", by_whome, false)
	tween.start()

func set_constructed(var by_whome, var instant : bool):
	if not instant:
		assert(state == State.UNDER_CONSTRUCTION)
	state = State.CONSTRUCTED
	if tile_owner.player == -1:
		tile_owner.player = by_whome.player
	if tile_target.player == -1:
		tile_target.player = by_whome.player
	update_pathing()
	tile_owner.update_owner_emission()
	tile_target.update_owner_emission()
	# Can we connect these out further?
	tile_owner.try_and_spread_monorail()
	tile_target.try_and_spread_monorail()
	transform.origin.y = 0
	if not instant:
		by_whome.job_finished()

func update_pathing():
	if state != State.CONSTRUCTED:
		return
	var pm = $"../../PathingManager"
	for p in range(GlobalVars.MAX_PLAYERS):
		pm.disconnect_tiles(p, tile_owner, tile_target)
		match pathing[p]:
			Pathing.BIDIRECTIONAL:
				pm.connect_tiles(p, tile_owner, tile_target, true)
			Pathing.OWNER_TO_TARGET:
				pm.connect_tiles(p, tile_owner, tile_target, false)
			Pathing.TARGET_TO_OWNER:
				pm.connect_tiles(p, tile_target, tile_owner, false)
			Pathing.NONE:
				pass

