extends ProgressBar

func _process(delta: float) -> void:
	
	if Global.health > max_value: max_value = Global.health
	value = Global.health

func _ready() -> void:
	max_value = Global.health
	
	
