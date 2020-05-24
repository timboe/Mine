extends Spatial

onready var blueprint_enabled : ShaderMaterial = preload("res://materials/blueprint_shadermaterial.tres")
onready var blueprint_disabled : ShaderMaterial = preload("res://materials/blueprint_disabled_shadermaterial.tres")

func _ready():
	if get_name() == "BlueprintsEnabled":
		recursive_set_blueprint(self, blueprint_enabled)
		get_child(0).queue_free()
	elif get_name() == "BlueprintsDisabled":
		recursive_set_blueprint(self, blueprint_disabled)
		get_child(0).queue_free()

func recursive_set_blueprint(var node, var mat : ShaderMaterial):
	for c in range(node.get_child_count()):
		recursive_set_blueprint(node.get_child(c), mat)
	if node is MeshInstance:
		# Material override
		for i in range(node.get_surface_material_count()):
			node.set_surface_material(i, mat)
	elif node is Particles or node is Zapper:
		node.queue_free()
