extends Sprite2D

var fade_speed = 4.0

func _process(delta: float) -> void:
	modulate.a -= fade_speed * delta
	if modulate.a <= 0:
		queue_free()
