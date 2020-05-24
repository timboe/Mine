extends Spatial

class_name BuildingManager

enum Type {NONE, MCP, GEN, VAT}

var building_id : int = 0
var building_dictionary : Dictionary
var doing_placement : int = Type.NONE
var placement_player : int = -1

onready var energy_manager = $"../EnergyManager"
onready var job_manager = $"../JobManager"
onready var camera_manager = $"../CameraManager"

const HIDE_DEPTH = -50

var enabled_blueprints := {}
var disabled_blueprints := {}
var building_instances := {}

func _ready():
	enabled_blueprints[Type.MCP] = $"../BlueprintsEnabled/MCP"
	enabled_blueprints[Type.GEN] = $"../BlueprintsEnabled/Generator"
	enabled_blueprints[Type.VAT] = $"../BlueprintsEnabled/Vat"
	#
	disabled_blueprints[Type.MCP] = $"../BlueprintsDisabled/MCP"
	disabled_blueprints[Type.GEN] = $"../BlueprintsDisabled/Generator"
	disabled_blueprints[Type.VAT] = $"../BlueprintsDisabled/Vat"
	#
	building_instances[Type.MCP] = $"../ObjectFactory/MCP"
	building_instances[Type.GEN] = $"../ObjectFactory/Generator"
	building_instances[Type.VAT] = $"../ObjectFactory/Vat"
	
func show_blueprint(var player : int, var type : int):
	doing_placement = type
	placement_player = player

func update_blueprint(var tile : TileElement):
	assert(doing_placement != Type.NONE)
	if tile.state != tile.State.DESTROYED or tile.building != null:
		enabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
		disabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
		return
	if tile.player == placement_player and energy_manager.can_afford(placement_player, 10.0) and get_access_tile(placement_player, tile) != null:
		enabled_blueprints[doing_placement].transform = tile.get_global_transform()
		enabled_blueprints[doing_placement].transform.origin.y = -HIDE_DEPTH
		disabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
	else:
		disabled_blueprints[doing_placement].transform = tile.get_global_transform()
		disabled_blueprints[doing_placement].transform.origin.y = -HIDE_DEPTH
		enabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH

func get_access_tile(var player : int, var tile : TileElement):
	for n in tile.paths.keys():
		if n.building != null:
			continue
		if n.player == placement_player:
			return n
	return null

func place_blueprint(var tile : TileElement):
	assert(doing_placement != Type.NONE)
	update_blueprint(tile)
	if tile.state != tile.State.DESTROYED:
		return
	if tile.building != null:
		return
	if tile.player != placement_player:
		return
	if not energy_manager.can_afford(placement_player, 10.0):
		return
	var access = get_access_tile(placement_player, tile)
	if access == null:
		return
	#
	var new_building = building_instances[doing_placement].duplicate()
	new_building.id = building_id
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
	match doing_placement:
		Type.MCP:
			new_building.add_to_group("mcp")
		Type.GEN:
			new_building.add_to_group("generator")
		Type.VAT:
			new_building.add_to_group("vat")
	#
	enabled_blueprints[doing_placement].transform.origin.y = HIDE_DEPTH
	new_blueprint.transform.origin.y = 0
	new_building.transform = tile.get_global_transform()
	new_building.transform.origin.y = 0
	#
	job_manager.add_job(placement_player, job_manager.JobType.CONSTRUCT_BUILDING, access, tile)
	camera_manager.add_trauma(1.0, tile.pathing_centre)
	#
	doing_placement = Type.NONE
	placement_player = -1

func is_placing() -> bool:
	return doing_placement != Type.NONE
