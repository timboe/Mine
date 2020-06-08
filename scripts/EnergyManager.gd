extends Spatial
# warning-ignore-all:return_value_discarded

var energy_cache : Array # Array of vector2 per player. X=total capacity, Y=total energy
var to_add : Array # Array of float per player. Used to add up how much to add per player per tick
var player_energy_control : ProgressBar
onready var tween : Tween = $Tween
onready var ANIM_TIME : float = $AddEnergy.wait_time / 2.0

func _ready():
	for _p in GlobalVars.MAX_PLAYERS:
		energy_cache.push_back( Vector2(0.0, 0.0) )
		to_add.push_back( 0.0 )
	player_energy_control = get_tree().get_root().find_node("EnergyBar", true, false)

func can_afford(var player : int, var amount : float) -> bool:
	return energy_cache[ player ].y >= amount
	
func try_spend(var player : int, var amount : float) -> bool:
	if not can_afford(player, amount):
		return false # We know from the last tick's cache that we don't have enough energy
	
	# Try and actually spend the energy
	var to_remove := amount
	for vat in get_tree().get_nodes_in_group("vat"):
		if vat.location != null and vat.location.player != player:
			continue
		to_remove = vat.remove(to_remove)
		if to_remove == 0.0: # This is an explicit return, so shouldn't need a delta
			break
			
	# Check we suceeded. Possible e.g. that someone just stole a whole load of energy
	# after the last _on_AddEnergy_timeout, so our cache is out-of-date
	if to_remove > 0.0:
		# We didn't manage to collect all that energy! Rare. Issue refund.
		# This refund should definitly work. Hence assert
		# Suppose amount=10, and now to_remove=2. Need to refund the 8 energy.
		print("try_spend failed after the cache check, player",player,
			" tried to spend ",amount,", could not extract ",to_remove,
			", hence refunding ", amount-to_remove)
		assert( add_energy(player, amount - to_remove) )
		return false # could not afford
		
	# Could afford, and energy was deducted
	return true

func add_energy(var player : int, var e : float) -> float:
	for vat in get_tree().get_nodes_in_group("vat"):
		if vat.location != null and vat.location.player != player:
			continue
		e = vat.add(e)
		if e == 0.0:
			return 0.0
	return e

func _on_AddEnergy_timeout():
	# Clear the to-add array, cached array
	for p in range(GlobalVars.MAX_PLAYERS):
		to_add[p] = 0.0
		energy_cache[p].x = 0.0
		energy_cache[p].y = 0.0
		
	# Populate the to-add array
	for gen in get_tree().get_nodes_in_group("generator"):
		if gen.location != null:
			to_add[ gen.location.player ] += gen.get_tick_energy()
			
	# Give the energy
	for p in range(GlobalVars.MAX_PLAYERS):
		var _wasted := add_energy(p, to_add[p])
		if (_wasted > 0):
			print(_wasted, " energy wasted for player ", p)
		
	# Update animation and collect statistics on total energy
	for vat in get_tree().get_nodes_in_group("vat"):
		vat.animate(ANIM_TIME, energy_cache)
		
	# Update the UI
	if energy_cache[0].x > 0.0:
		tween.interpolate_property(player_energy_control, "max_value",
			null, energy_cache[0].x, ANIM_TIME)
		tween.interpolate_property(player_energy_control, "value",
			null, energy_cache[0].y, ANIM_TIME)
		tween.start()
