extends RigidBody2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("platform"):
		body.take_damage(2)
		queue_free()
	elif body.is_in_group("enemy"):
		body.take_damage(2, global_position)
		queue_free()
	elif body.name != "Player":
		queue_free()
		
