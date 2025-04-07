extends TextureRect


func _process(delta: float) -> void:
	$"../Label".text = str(Global.fireball_count)
	if Global.fireball_count > 0:
		modulate = Color.WHITE
		$"../Label".visible = true 
	else:
		modulate = Color.BLACK
		$"../Label".visible = false
