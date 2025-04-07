extends PointLight2D
var base_energy := 0.5
var flicker_timer := 0.0

func _ready():
	base_energy = energy
	randomize()

func _process(delta):
	flicker_timer -= delta
	if flicker_timer <= 0:
		# Occasionally go completely dark like it's shorting out
		if randi() % 10 == 0:
			energy = 0
			flicker_timer = randf_range(0.05, 0.3)
		else:
			energy = base_energy * randf_range(0.2, 0.8)
			flicker_timer = randf_range(0.01, 0.1)
