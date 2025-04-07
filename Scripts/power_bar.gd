extends ProgressBar
@export var power_icon = TextureRect

func _process(delta: float) -> void:
	if Global.power_time > 0:
		max_value = Global.power_duration
		value = Global.power_time
		visible = true
		power_icon.modulate = Color.WHITE
	else:
		visible = false
		power_icon.modulate = Color.BLACK
		
