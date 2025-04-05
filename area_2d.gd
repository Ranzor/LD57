extends Area2D

@export var tilemap : TileMapLayer

func _process(delta: float) -> void:
	position.y += 10 * delta


func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		var hit_pos = global_position  # Use the position of the sword hitbox
		var local_pos = tilemap.to_local(hit_pos)
		var coords = tilemap.local_to_map(local_pos)
		print("Hit pos:", hit_pos)
		print("Local pos:", local_pos)
		print("Tile coords:", coords)
		body.set_cell(coords,0,Vector2i(0,0))
