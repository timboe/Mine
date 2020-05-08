tool
extends Node


onready var rand = RandomNumberGenerator.new()

onready var SELECTING_MODE := false
var SELECTED_NODE = null

const FLOOR_HEIGHT : float = 20.0


