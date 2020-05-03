extends MeshInstance

var id := 0

enum State {BUILT, SELECTED, BEING_DESTROYED, DESTROYED}
var state = State.BUILT 
var particles_instance : Particles

onready var mat : SpatialMaterial = get_surface_material(0)
onready var parent_physics_body : StaticBody = get_parent()
onready var tween : Tween = $"../../../Tween"
onready var HEIGHT : float = $"../../../../CairoTilesetGen".HEIGHT

const HOVER_COLOUR : Color = Color(0/255.0, 45/255.0, 227/255.0)
const SELECT_COLOUR : Color = Color(125/255.0, 125/255.0, 0/255.0) # Not used directly
const HOVER_SELECT_COLOUR := HOVER_COLOUR + SELECT_COLOUR
const HOVER_REMOVE_COLOUR : Color = Color(160/255.0, 0/255.0, 56/255.0)
const FADE_TIME : float = 5.0

func setID(var i: int):
	id = i
	
func _ready():
	parent_physics_body.connect("mouse_entered", self, "_on_StaticBody_mouse_entered")
	parent_physics_body.connect("mouse_exited", self, "_on_StaticBody_mouse_exited")
	parent_physics_body.connect("input_event", self, "_on_StaticBody_input_event")
	mat.emission_enabled = false
	mat.emission_energy = 1.0

func update_HOVER_color(var is_hover : bool):
	if state >= State.SELECTED:
		return
	if is_hover:
		mat.emission = HOVER_COLOUR
		mat.emission_enabled = true
	else:
		mat.emission_enabled = false
		
func update_selected():
	if state >= State.BEING_DESTROYED:
		return
	state = State.SELECTED if GlobalVars.SELECTING_MODE else State.BUILT
	tween.remove(self.mat)
	tween.remove(self)
	if state == State.SELECTED:
		print("Do Tween")
		tween.interpolate_property(self.mat, "emission",
			HOVER_SELECT_COLOUR, HOVER_REMOVE_COLOUR, FADE_TIME,
			Tween.TRANS_CIRC, Tween.EASE_IN)
		tween.interpolate_callback(self, FADE_TIME, "do_deconstruct_a")
		tween.start()
	else:
		update_HOVER_color(true)

func do_deconstruct_a():
	print("Remove " + str(id))
	state = State.BEING_DESTROYED
	var thunk_time := 0.2
	tween.interpolate_property(parent_physics_body, "translation:y",
		null, -HEIGHT * 0.1, thunk_time,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_property(self.mat, "emission_energy",
		1.0, 0.0, thunk_time,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_callback(self, thunk_time, "do_deconstruct_b")
	tween.start()
	
func do_deconstruct_b():
	mat.emission_enabled = false
	tween.interpolate_property(parent_physics_body, "translation:y",
		null, -HEIGHT, FADE_TIME,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_callback(self, FADE_TIME, "done_deconstruct")
	tween.start()
	particles_instance = $"../../../Particles".duplicate()
	parent_physics_body.add_child(particles_instance)
	particles_instance.emitting = true
	
func done_deconstruct():
	print("Removed " + str(id))
	state = State.DESTROYED
	particles_instance.queue_free()
	#var probe : GIProbe = get_tree().get_root().get_node("World/GIProbe")
	#probe.bake()

func _on_StaticBody_mouse_entered():
	update_HOVER_color(true)
	if Input.is_mouse_button_pressed(1):
		update_selected()

func _on_StaticBody_mouse_exited():
	update_HOVER_color(false)
	
func _on_StaticBody_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			GlobalVars.SELECTING_MODE = (state == State.BUILT)
			update_selected()

