extends Timer

var start = 0

func _ready():
	$"../Particles/A1".emitting = false
	$"../Particles/B1".emitting = false
	$"../Particles/A2".emitting = false
	$"../Particles/B2".emitting = false
	$"../Particles/A3".emitting = false
	$"../Particles/B3".emitting = false

func _on_ParticlesStarter_timeout():
	start += 1
	match start:
		1:
			$"../Particles/A1".emitting = true
			$"../Particles/B1".emitting = true
		2:
			$"../Particles/A2".emitting = true
			$"../Particles/B2".emitting = true
			wait_time /= 2.0
		3:
			$"../Particles/A3".emitting = true
			$"../Particles/B3".emitting = true
			self.stop()
