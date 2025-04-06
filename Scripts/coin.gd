extends RigidBody2D

var has_collided = false
var can_collect = false
var dealt_damage = false

func _ready() -> void:
	randomize()
	$PickUp.body_entered.connect(_on_body_entered)
	$Timer.start(randf_range(3.0,5.0))
	$SpawnTimer.start(0.2)
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		if collider is TileMapLayer:
			var tile_pos = collider.local_to_map(state.get_contact_collider_position(i))
			if not has_collided:
				collider.damage_tile(tile_pos)
	
func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and can_collect:
		body.collect_coin()
		## TODO Pickup particles=?
		queue_free()
	
	if body.is_in_group("platform") and !dealt_damage:
		body.take_damage(1)
		dealt_damage = true



func _on_timer_timeout() -> void:
	queue_free()


func _on_spawn_timer_timeout() -> void:
	can_collect = true
