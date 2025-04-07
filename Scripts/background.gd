extends TextureRect

@export var start_color := Color("#0a0a1a")  # Dark blue
@export var end_color := Color("#330000")     # Deep red
@onready var max_depth = Global.max_depth  * 2            # Match your depth_for_max_darkness

func _process(delta):
	var player_depth = $"../../../Player".global_position.y
	var depth_factor = clamp(player_depth / max_depth, 0.0, 1.0)
	
	# Blend colors based on depth
	modulate = start_color.lerp(end_color, depth_factor)
	
	# Optional: Darken texture with depth
	modulate.a = 1.0 - depth_factor * 0.5
