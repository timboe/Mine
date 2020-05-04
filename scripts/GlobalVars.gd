extends Node

enum CameraStatus {OVERHEAD, TO_FPS, FPS, TO_OVERHEAD}
onready var camera_status : int = CameraStatus.OVERHEAD

onready var rand = RandomNumberGenerator.new()

onready var SELECTING_MODE := false
var SELECTED_NODE = null

const FLOOR_HEIGHT : float = 20.0
