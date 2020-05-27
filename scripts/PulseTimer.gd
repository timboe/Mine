extends Timer

var gen_start = 0
var pulse := 0

func _on_PulseTimer_timeout():
	for mcp in get_tree().get_nodes_in_group("mcp"):
		mcp.on_PulseTimer_timeout(pulse)
	for gen in get_tree().get_nodes_in_group("generator"):
		gen.on_PulseTimer_timeout(pulse)
	pulse += 1

#func _on_StartGenerator_timeout():
#	gen_start += 1
#	match gen_start:
#		1:
#			$"../ObjectFactory/Generator/Particles/A1".emitting = true
#			$"../ObjectFactory/Generator/Particles/B1".emitting = true
#		2:
#			$"../ObjectFactory/Generator/Particles/A2".emitting = true
#			$"../ObjectFactory/Generator/Particles/B2".emitting = true
#			#$"../StartGenerator".wait_time /= 2.0
#		3:
#			$"../ObjectFactory/Generator/Particles/A3".emitting = true
#			$"../ObjectFactory/Generator/Particles/B3".emitting = true
#			$"../StartGenerator".stop()
