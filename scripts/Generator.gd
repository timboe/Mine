extends Building

const BASE_GENERATION := 10.0
var generation := 0.0

func _ready():
	if location != null:
		add_to_group("generator")

func get_tick_energy() -> float:
	if state != State.CONSTRUCTED:
		return 0.0
	return BASE_GENERATION + generation
