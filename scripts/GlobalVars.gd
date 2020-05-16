tool
extends Node


var LEVEL = load("res://levels/skirmish_01.gd")

onready var rand = RandomNumberGenerator.new()

onready var SELECTING_MODE := false
var SELECTED_NODE = null

const FLOOR_HEIGHT : float = 20.0 # Visible floor-to-roof of time 
const TILE_OFFSET : float = 1.95 # Tile extends this far below floor level
const GRID_OFFSET : float = 2.0 # Grid is this far below floor level 

