tool
extends StaticBody

onready var top_a : MeshInstance = $MCPTop
onready var top_b : MeshInstance = $MCPFaceTop
onready var bot_a : MeshInstance = $MCPBottom
onready var bot_b : MeshInstance = $MCPFaceBottom

const A_VELOCITY = 100

func _ready():
	pass

func _process(delta):
	top_a.rotate_object_local(Vector3.UP, delta * A_VELOCITY)
	top_b.rotate_object_local(Vector3.UP, delta * A_VELOCITY)
	bot_a.rotate_object_local(Vector3.UP, delta * A_VELOCITY)
	bot_b.rotate_object_local(Vector3.UP, delta * A_VELOCITY)
