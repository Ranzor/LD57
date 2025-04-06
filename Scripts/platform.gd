extends StaticBody2D

var health = 2

var biome_dirt = 0
var biome_cave = 4
var biome_lava = 8

func take_damage(amount : int):
	health -= amount
	if health <= 0:
		## TODO: Add destruction particle effect here.
		queue_free()
	else:
		$Sprite2D.frame += 1
	pass
	
func set_biome(biome):
	
	match biome:
		0:
			$Sprite2D.frame = biome_dirt
		1:
			$Sprite2D.frame = biome_cave
		2:
			$Sprite2D.frame = biome_lava
	
	pass
