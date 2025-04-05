extends Camera2D

@export var decay_rate = 3.0
@export var max_offset = Vector2(16,8)
@export var roll = true
@export var max_roll = 0.1

var trauma = 0.0
var trauma_power = 2

func _ready() -> void:
	randomize()
	randomize()
	randomize()
	
func _process(delta: float) -> void:
	if trauma > 0:
		trauma = max(trauma - decay_rate * delta, 0)
		_apply_shake()
		
func apply_shake(intensity = 0.5):
	trauma = min(trauma + intensity, 1.0)
	
func _apply_shake():
	var amount = pow(trauma, trauma_power)
	
	offset = Vector2(
		max_offset.x * amount * randf_range(-1,1),
		max_offset.y * amount * randf_range(-1,1)
	)
	
	if roll:
		rotation = max_roll * amount * randf_range(-1,1)
