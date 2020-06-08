extends Node

class_name PathingManager

onready var astar : Array 

func _ready():
	# The 0-MAX_PLAYERS networks are used to track the monorail network (with 
	# per-player one-way instructions included)
	# The +1 network is used to track the destroyed tiles network
	for _i in range(GlobalVars.MAX_PLAYERS + 1):
		astar.push_back( AStar.new() )

func add_tile(var tile : TileElement):
	for i in range(GlobalVars.MAX_PLAYERS + 1):
		astar[i].add_point( tile.get_id(), tile.pathing_centre )

func disconnect_tiles(var player : int, var a : TileElement, var b : TileElement):
	astar[player].disconnect_points(a.get_id(), b.get_id())

func are_tiles_connected(var player : int, var a : TileElement, var b : TileElement) -> bool:
	return (pathfind(player, a, b).size() > 0)

func connect_tiles(var player : int, var from : TileElement, var to : TileElement, var bidirectional : bool):
	astar[player].connect_points(from.get_id(), to.get_id(), bidirectional) 

func pathfind(var player, var from : TileElement, var to : TileElement) -> PoolIntArray:
	return astar[player].get_id_path(from.get_id(), to.get_id())

func get_point(var id : int) -> Vector3:
	return astar[0].get_point_position(id) # we could have used any of the instances
	
func get_tile(var id : int) -> TileElement:
	return $"../../TileManager".tile_dictionary[id]
