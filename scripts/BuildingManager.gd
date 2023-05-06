extends Spatial

class_name BuildingManager

enum Type {NONE, MCP, GEN, VAT, BAR}

var building_id : int = 0
var building_dictionary : Dictionary
var doing_placement : int = Type.NONE
var placement_player : int = -1

onready var energy_manager = $"../EnergyManager"
onready var camera_manager = $"../CameraManager"

const HIDE_DEPTH = -50

var enabled_blueprints := {}
var disabled_blueprints := {}
var building_instances := {}

func _ready():
	enabled_blueprints[Type.MCP] = $"../BlueprintsEnabled/MCP"
	enabled_blueprints[Type.GEN] = $"../BlueprintsEnabled/Generator"
	enabled_blueprints[Type.VAT] = $"../BlueprintsEnabled/Vat"
	enabled_blueprints[Type.BAR] = $"../BlueprintsEnabled/Barrier"
	#
	disabled_blueprints[Type.MCP] = $"../BlueprintsDisabled/MCP"
	disabled_blueprints[Type.GEN] = $"../BlueprintsDisabled/Generator"
	disabled_blueprints[Type.VAT] = $"../BlueprintsDisabled/Vat"
	disabled_blueprints[Type.BAR] = $"../BlueprintsDisabled/Barrier"
	#
	building_instances[Type.MCP] = $"../ObjectFactory/MCP"
	building_instances[Type.GEN] = $"../ObjectFactory/Generator"
	building_instances[Type.VAT] = $"../ObjectFactory/Vat"
	building_instances[Type.BAR] = $"../ObjectFactory/Barrier"
	
func show_blueprint(var player : int, var type : int):
	doing_placement = type
	placement_player = player

func can_place_here(var tile : TileElement):
	if doing_placement == Type.BAR:
		return (tile.state == tile.State.BUILT)
	else:
		return (tile.state == tile.State.DESTROYED)
		
func check_ownership(var tile : TileElement):
	if doing_placement == Type.BAR:
		return (tile.player == -1)
	else:
		return (tile.player == placement_player)
		
func check_access(var tile : TileElement):
	if doing_placement == Type.BAR:
		return tile.get_access_tiles_wall(placement_player)
	else:
		return tile.get_access_tiles()

func update_blueprint(var tile : TileElement):
	assert(doing_placement != Type.NONE)
	if not can_place_here(tile) or tile.building != null:
		enabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
		disabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
		return
	if check_ownership(tile) and energy_manager.can_afford(placement_player, 10.0) and check_access(tile).size() > 0:
		enabled_blueprints[doing_placement].transform = tile.get_global_transform()
		enabled_blueprints[doing_placement].transform.origin.y = -HIDE_DEPTH
		disabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
	else:
		disabled_blueprints[doing_placement].transform = tile.get_global_transform()
		disabled_blueprints[doing_placement].transform.origin.y = -HIDE_DEPTH
		enabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH

func place_blueprint(var tile : TileElement):
	assert(doing_placement != Type.NONE)
	update_blueprint(tile)
	if not can_place_here(tile):
		return
	if tile.building != null:
		return
	if not check_ownership(tile):
		return
	if not energy_manager.can_afford(placement_player, 10.0):
		return
	var access_tiles : Array = check_access(tile)
	if access_tiles.size() == 0:
		return
	#
	var new_building = building_instances[doing_placement].duplicate()
	new_building.id = building_id
	new_building.type = doing_placement
	building_dictionary[building_id] = new_building
	building_id += 1
	tile.set_building(new_building) 
	# Set building before set blueprint (to update monorail correctly)
	var new_blueprint = enabled_blueprints[doing_placement].duplicate()
	new_building.set_blueprint(new_blueprint)
	#
	add_child(new_building)
	add_child(new_blueprint)
	#
	enabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
	new_blueprint.transform.origin.y = 0
	new_building.transform = tile.get_global_transform()
	new_building.transform.origin.y = 0
	#
	for z in get_tree().get_nodes_in_group("zoombas"):
		z.path.resize(0) # Force re-pathing
	#
	new_building.queue_construction_jobs(placement_player)
	camera_manager.add_trauma(1.0, tile.pathing_centre)
	#
	doing_placement = Type.NONE
	placement_player = -1

# Place a pre-constructed building. Used in setting up the level
func place_building(var tile : TileElement, var type : int):
	var b : StaticBody = building_instances[type].duplicate()
	b.location = tile
	b.state = b.State.CONSTRUCTED
	b.transform = tile.get_global_transform()
	b.transform.origin.y = 0
	tile.set_building(b)
	add_child(b)
	if tile.state != tile.State.DESTROYED:
		tile.set_destroyed()

func is_placing() -> bool:
	return doing_placement != Type.NONE
