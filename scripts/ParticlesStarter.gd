extends Timer

var start = 0

func _on_ParticlesStarter_timeout():
	start += 1
	print("Start ", start)
	match start:
		1:
			$"../Particles/A1".emitting = true
			$"../Particles/B1".emitting = true
		2:
			$"../Particles/A2".emitting = true
			$"../Particles/B2".emitting = true
		3:
			$"../Particles/A3".emitting = true
			$"../Particles/B3".emitting = true
		_:
			self.stop()
