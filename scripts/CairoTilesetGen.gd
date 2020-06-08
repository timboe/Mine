extends Spatial
class_name CairoTilesetGen

onready var base_material : SpatialMaterial = preload("res://materials/aluminium.tres")
onready var outline_material : ShaderMaterial = preload("res://materials/grid_edges.tres")
onready var disabled_material : ShaderMaterial = preload("res://materials/disabled.tres")
onready var cairo = $Cairo
onready var tiles : Node = $Tiles
onready var monorail_mm : MultiMeshInstance = $MonorailMultimesh
onready var building_manager : BuildingManager = $"../BuildingManager"

var generated = false

var tile_id : int = 0
var tile_dictionary : Dictionary

var rand := RandomNumberGenerator.new()

onready var tile_script = preload("res://scripts/TileElement.gd")


func populate(var physics_body_instance : StaticBody, var rotation_group : String):
	var mesh_instance = MeshInstance.new()
	if not Engine.editor_hint: physics_body_instance.set_id(tile_id)
	tile_dictionary[tile_id] = physics_body_instance
	var mat : Material
	if tile_id in GlobalVars.LEVEL.IMMUTABLE or not physics_body_instance.visible:
		physics_body_instance.visible = true # Note: was being used as a flag
		mat = disabled_material
		if not Engine.editor_hint: physics_body_instance.set_disabled()
		physics_body_instance.add_to_group("disabled")
	elif tile_id in GlobalVars.LEVEL.INVISIBLE:
		# Similar to immutable, but seethrough too
		mesh_instance.visible = false
		if not Engine.editor_hint: physics_body_instance.set_disabled()
		physics_body_instance.add_to_group("invisible")
	else:
		mat = base_material.duplicate()
		physics_body_instance.add_to_group("interactive")
		physics_body_instance.add_to_group(rotation_group)
	tile_id += 1
	mesh_instance.use_in_baked_light = true
	mesh_instance.set_mesh(cairo.mesh)
	mesh_instance.set_surface_material(0, mat)
	mesh_instance.set_surface_material(1, outline_material)
	physics_body_instance.add_child(mesh_instance)
	physics_body_instance.add_child(cairo.get_child(0).duplicate())
	var ray := RayCast.new()
	ray.translate(Vector3(cairo.UNIT/2.0, cairo.HEIGHT/2.0, cairo.UNIT/2.0))
	ray.cast_to = Vector3(50.0, 0, 0)
	physics_body_instance.add_child(ray)
	physics_body_instance.add_to_group("tiles")
	if not Engine.editor_hint: physics_body_instance.delayed_ready()
	
func check_disabled(var physics_body_instance : StaticBody) -> bool:
	var t_local : Vector3 = physics_body_instance.translation
	var t : Vector3 = physics_body_instance.to_global(t_local)
	var distance_v := Vector2()
	var max_outer : float = GlobalVars.LEVEL.TRIPLETS*3*cairo.UNIT*2
	if t.z < 0 or t.x < 0:
		distance_v.x = -min(t.x, t.z)
	if t.z > max_outer or t.x > max_outer:
		distance_v.y = max(t.x, t.z) - max_outer
	var distance = max(distance_v.x, distance_v.y)
	if distance > 0:
		physics_body_instance.visible = false # Used to communicate w below
		if distance > cairo.UNIT*4 and distance > rand.randf_range(0.0, cairo.UNIT*8):
			return true
	return false

func add_cluster(var xOff : int, var yOff : int):
	var spatial : Spatial = Spatial.new()
	var yMod : float = cairo.RIGHT_POINT__UP * xOff
	var xMod : float = cairo.RIGHT_POINT__UP * yOff
	spatial.translate(Vector3(yMod + yOff*(cairo.TOP_POINT__RIGHT + cairo.TOP_POINT__UP), 
		0, xOff*(cairo.UNIT + cairo.RIGHT_POINT__RIGHT) - xMod))
	var physics_body_a := StaticBody.new() # TL
	var physics_body_b := StaticBody.new() # BL
	var physics_body_c := StaticBody.new() # BR
	var physics_body_d := StaticBody.new() # TR
	physics_body_a.set_script(tile_script)
	physics_body_b.set_script(tile_script)
	physics_body_c.set_script(tile_script)
	physics_body_d.set_script(tile_script)
	physics_body_a.translate(Vector3(cairo.UNIT, -GlobalVars.TILE_OFFSET, 0))
	physics_body_b.translate(Vector3(cairo.UNIT, -GlobalVars.TILE_OFFSET, 0))
	physics_body_c.translate(Vector3(cairo.UNIT + cairo.RIGHT_POINT__UP,
		-GlobalVars.TILE_OFFSET, cairo.UNIT + cairo.RIGHT_POINT__RIGHT))
	physics_body_d.translate(Vector3(cairo.UNIT + cairo.RIGHT_POINT__UP,
		-GlobalVars.TILE_OFFSET, cairo.UNIT + cairo.RIGHT_POINT__RIGHT))
	physics_body_b.rotate_y(deg2rad(-90.0))
	physics_body_c.rotate_y(deg2rad(180.0))
	physics_body_d.rotate_y(deg2rad(90.0))
	spatial.add_child(physics_body_a)
	spatial.add_child(physics_body_b)
	spatial.add_child(physics_body_c)
	spatial.add_child(physics_body_d)
	tiles.add_child(spatial)
# warning-ignore-all:standalone_ternary
	physics_body_a.queue_free() if check_disabled(physics_body_a) else populate(physics_body_a, "tilesA")
	physics_body_b.queue_free() if check_disabled(physics_body_b) else populate(physics_body_b, "tilesB")
	physics_body_c.queue_free() if check_disabled(physics_body_c) else populate(physics_body_c, "tilesC")
	physics_body_d.queue_free() if check_disabled(physics_body_d) else populate(physics_body_d, "tilesD")

func _generate():
	tile_id = 0
	tile_dictionary.clear()
	rand.set_seed(GlobalVars.LEVEL.SEED)
	for i in range(0, tiles.get_child_count()):
		tiles.get_child(i).queue_free()
	var floor_v := Vector2()
	var border : int = GlobalVars.LEVEL.BORDER_TRIPLETS*3
	var arena : int = GlobalVars.LEVEL.TRIPLETS*3
	for x in range(-border, (arena*2) + border):
		for y in range(-border - arena, arena + border):
			floor_v = Vector2(floor(x/3.0), floor(y/3.0))
			if (y+border < 0 - floor_v.x  ||  y-border > arena - floor_v.x): continue
			if (x+border < 0 + floor_v.y  ||  x-border > arena + floor_v.y): continue
			add_cluster(x, y)
	set_physics_process(true)
	generated = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#_generate()

func _physics_process(var _delta):
	if not generated:
		return
	set_physics_process(false)
	print("Phys once")
	if Engine.editor_hint:
		return
	set_neighbours()
	disabled_tiles_to_multimesh()
	apply_loaded_level()
	add_monorail()
	apply_initial_monorail_and_zoomba()

func set_neighbours():
	for tile in get_tree().get_nodes_in_group("tiles"):
		var ray : RayCast = tile.get_child(2)
		for _a in range(10):
			ray.force_raycast_update()
			var c = ray.get_collider()
			if c != null and c.has_method("add_neighbour"):
				c.add_neighbour( tile )
				tile.add_neighbour( c )
			ray.rotate_object_local(Vector3.UP, 2.0*PI / 10.0)
		if tile.state == TileElement.State.BUILT:
			assert(tile.neighbours.size() == 5)
		ray.queue_free()
	var cap : MeshInstance = $"../ObjectFactory/MonorailCap"
	var cap_mm = $MonorailCapMultimesh
	cap_mm.multimesh = MultiMesh.new()
	cap_mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	cap_mm.multimesh.mesh = cap.mesh.duplicate()
	var interactive : Array = get_tree().get_nodes_in_group("interactive")
	cap_mm.multimesh.instance_count = interactive.size()
	var cap_count := 0
	for tile in interactive:
		var t = tile.get_child(0).get_transform()
		t.origin += Vector3(cairo.RIGHT_POINT__UP, 0.0, cairo.RIGHT_POINT__UP)
		t = tile.get_global_transform() * t
		t.origin.y = 0
		tile.pathing_centre = t.origin
		$PathingManager.add_tile(tile)
		t.origin.y = -0.6 # -0.6 to hide
		cap_mm.multimesh.set_instance_transform(cap_count, t)
		tile.monorail_cap_id = cap_count
		tile.monorail_cap_mm = cap_mm.multimesh
		cap_count += 1

func apply_loaded_level():
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.get_id() in GlobalVars.LEVEL.MCP:
			tile.player = GlobalVars.LEVEL.MCP.find( tile.get_id() )
			building_manager.place_building(tile, building_manager.Type.MCP)
		elif tile.get_id() in GlobalVars.LEVEL.DESTROYED:
			tile.set_destroyed()
			tile.translation.y = -cairo.HEIGHT

func add_monorail():
	# Our grid is formed of a tesselation of a four-tile primitive.
	# The linking relationships between neighbouring tiles depends on
	# the translation and rotations applied during the tesselation.
	# The four dictionaries below map this for each of the base tiles
	var tile_groups : Array = ["tilesA", "tilesB", "tilesC", "tilesD"]
	var monorail_groups : Array = ["mr1", "mr2", "mr3"]
	var tilesA_mapping : Dictionary = {"mr1": 2, "mr2": 3, "mr3": 4}
	var tilesB_mapping : Dictionary = {"mr1": 1, "mr2": 0, "mr3": 2}
	var tilesC_mapping : Dictionary = {"mr1": 4, "mr2": -1, "mr3": 2} # mr2 was 1 (dupe)
	var tilesD_mapping : Dictionary = {"mr1": 2, "mr2": -1, "mr3": 4} # mr2 was 3 (dupe)
	var tiles_mapping : Dictionary = {
		"tilesA": tilesA_mapping, "tilesB": tilesB_mapping,
		"tilesC": tilesC_mapping, "tilesD": tilesD_mapping}
	var total_monorails := 0
	total_monorails += get_tree().get_nodes_in_group("tilesA").size() * 3
	total_monorails += get_tree().get_nodes_in_group("tilesB").size() * 3
	total_monorails += get_tree().get_nodes_in_group("tilesC").size() * 2
	total_monorails += get_tree().get_nodes_in_group("tilesD").size() * 2
	monorail_mm.multimesh.set_instance_count(total_monorails) # This is high-balling it, due to DISABLED instances
	var mr_count := 0
	for tg in tile_groups:
		for tile in get_tree().get_nodes_in_group(tg):
			var mapping = tiles_mapping[tg]
			for mg in monorail_groups:
				# We don't need to make three links from every tile
				# Some are dupes. These are given -1 above
				var neighbour_id = mapping[mg]
				if neighbour_id == -1:
					continue;
				var target : StaticBody = tile.neighbours[ neighbour_id ]
				if target.state == TileElement.State.BUILT or target.state == TileElement.State.DESTROYED:
					var mr : Monorail = monorail_mm.new_mr(mr_count)
					var t : Transform = tile.get_child(0).get_transform()
					if mg == "mr2":
						t = t.rotated(Vector3.UP, deg2rad(60))
						# This is broken in the new coordinate system... this is good enough TODO - fix!
						t.origin += Vector3(0.5 * cairo.RIGHT_POINT__UP, 0.0, 2 * cairo.RIGHT_POINT__UP)
						#t = tile.get_global_transform() * t
					elif mg == "mr3":
						t = t.rotated(Vector3.UP, deg2rad(120))
						# As above - ugly & not precise
						t.origin += Vector3(1.6 * cairo.RIGHT_POINT__UP, 0.0, 2.0 * cairo.RIGHT_POINT__UP)
						#t = tile.get_global_transform() * t
					else:
						t.origin += Vector3(0.0, 0.0, cairo.RIGHT_POINT__UP)
					t = tile.get_global_transform() * t
					t.origin.y = -0.5 # Hide
					monorail_mm.multimesh.set_instance_transform(mr_count, t)
					tile.links_to(target, mr, true)
					mr_count += 1
	assert(mr_count <= total_monorails)
	monorail_mm.multimesh.set_visible_instance_count(mr_count)


func apply_initial_monorail_and_zoomba():
	print(monorail_mm.monorail_dict[10], " ", monorail_mm.monorail_dict[10].monorail_id)
	print(monorail_mm.monorail_dict[11], " ", monorail_mm.monorail_dict[11].monorail_id)
	for id in GlobalVars.LEVEL.MCP:
		var player = GlobalVars.LEVEL.MCP.find( id )
		var tile : TileElement = tile_dictionary[id] # Get ID of MCP tile
		tile.player = player
		var done := false
		for n in tile.neighbours:
			if n.state == TileElement.State.DESTROYED: # Find a vaid initial link
				done = true
				tile.building.spawn_start_loc = n
				var zoomba = tile.building.add_zoomba()
				var mr : Monorail = tile.paths[n]
				mr.set_constructed(zoomba, true) # Sets as constucted by player
				break
		tile.building.update_monorail()
		if not done:
			print("Could not connect MCP to starting tile!")
			assert(false)

func disabled_tiles_to_multimesh():
	var disabled := get_tree().get_nodes_in_group("disabled")
	var disabled_mm := $DisabledTileMultimesh
	disabled_mm.set_multimesh(MultiMesh.new())
	disabled_mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	disabled_mm.multimesh.mesh = cairo.mesh.duplicate()
	disabled_mm.multimesh.instance_count = disabled.size()
	for i in range(disabled.size()):
		disabled_mm.multimesh.set_instance_transform(i, disabled[i].get_global_transform())
		disabled[i].get_child(0).queue_free()
