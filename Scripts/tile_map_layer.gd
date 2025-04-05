extends TileMapLayer

var tile_health = {}

func damage_tile(tile_pos: Vector2i):
	if !tile_health.has(tile_pos):
		tile_health[tile_pos] = 2
	
	tile_health[tile_pos] -= 1
	
	if tile_health[tile_pos] <= 0:
		set_cell(tile_pos,0,Vector2i(-1,-1))
		tile_health.erase(tile_pos)
		_spawn_break_effect(tile_pos)
	else:
		set_cell(tile_pos,0,Vector2i(1,0))
		
func _spawn_break_effect(pos: Vector2i):
	## TODO: Particle effect for destroyed tiles
	#var effect = preload("res://effects/break_particles.tscn").instantiate()
	#effect.position = map_to_local(pos)
	#add_child(effect)
	pass
