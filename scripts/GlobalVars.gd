tool
extends Node

var LEVEL = load("res://levels/skirmish_01.gd")

onready var rand = RandomNumberGenerator.new()

onready var SELECTING_MODE := false
var SELECTED_NODE = null

const FLOOR_HEIGHT : float = 20.0


