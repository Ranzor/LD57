extends RigidBody2D

@export var collect_particles : PackedScene

var has_collided = false
var can_collect = false
var dealt_damage = false

@export var audioPlayer = AudioStreamPlayer2D
@export var coin_sound = AudioStreamWAV
var hasPlayed = false

func _ready() -> void:
	randomize()
	$PickUp.body_entered.connect(_on_body_entered)
	$Timer.start(randf_range(3.0,7.0))
	$SpawnTimer.start(0.2)
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		if collider is TileMapLayer:
			var tile_pos = collider.local_to_map(state.get_contact_collider_position(i))
			if not has_collided:
				collider.damage_tile(tile_pos)
				
func _process(delta: float) -> void:
	if not hasPlayed:
		$AudioStreamPlayer2D.play()
		hasPlayed = true
	
func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and can_collect:
		body.collect_coin()
		## TODO Pickup particles=?
		queue_free()
	
	if body.is_in_group("platform") and !dealt_damage:
		body.take_damage(1)
		dealt_damage = true

func spawn_particles():
	var particles = collect_particles.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	pass


func _on_timer_timeout() -> void:
	spawn_particles()
	queue_free()


func _on_spawn_timer_timeout() -> void:
	can_collect = true
