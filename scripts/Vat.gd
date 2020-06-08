extends Building
# warning-ignore-all:return_value_discarded

class_name Vat

const FULL_Y := 10.5
const EMPTY_Y := -7.5
const HEIGHT := FULL_Y - EMPTY_Y

const CAPACITY := 100.0 * 60.0
var capacity_mod := 0.0
var contains := 0.0 setget set_contains

var liquid = null

func _ready():
	if location != null:
		add_to_group("vat")
	if has_node("Liquid"):
		liquid = $Liquid

func get_capacity():
	return CAPACITY + capacity_mod
		
func animate(var time : float, var total_energy_cache : Array):
	if location != null and state == State.CONSTRUCTED:
		total_energy_cache[ location.player ].x += get_capacity()
		total_energy_cache[ location.player ].y += contains
	if liquid != null:
		tween.remove(liquid)
		tween.interpolate_property(liquid, "translation:y", null,
			EMPTY_Y + (contains / CAPACITY) * HEIGHT, time)
		tween.start()
		
func set_contains(var c : float):
	contains = c
	assert(contains <= get_capacity())

func add(var to_add : float) -> float:
	if state != State.CONSTRUCTED:
		return to_add
	var remainder : float = contains + to_add - get_capacity()
	if remainder > 0:
		set_contains(get_capacity())
		#print(remainder)
		return remainder
	else:
		set_contains(contains + to_add)
		#print("exactly 0")
		return 0.0
		
func remove(var to_remove : float) -> float:
	if state != State.CONSTRUCTED:
		return to_remove
	if to_remove <= contains:
		set_contains(contains - to_remove)
		return 0.0
	else:
		to_remove -= contains
		set_contains(0.0)
		return to_remove
		
