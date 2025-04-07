extends StaticBody2D

var health = 2

@export var break_particles : PackedScene

var biome_dirt = 0
var biome_cave = 4
var biome_lava = 8

func take_damage(amount : int):
	health -= amount
	if health <= 0:
		spawn_break_particles()
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

func spawn_break_particles():
	var particles = break_particles.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
