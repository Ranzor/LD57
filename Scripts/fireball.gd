# Fireball.gd
extends Area2D

@export var throw_speed := 200.0
@export var upward_force := -100
@export var grav := 980.0
@export var shrapnel_scene : PackedScene
@export var shrapnel_amount = 25

var velocity := Vector2.ZERO
var direction := 1
var has_exploded := false

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var particles = $TrailParticles
@onready var explosion_particles = $ExplosionParticles

func _ready():
	velocity = Vector2(throw_speed * direction, upward_force)
	body_entered.connect(_on_body_entered)
	$Timer.start(2.0)  # Failsafe timer

func _physics_process(delta):
	if has_exploded: return
	
	velocity.y += grav * delta
	position += velocity * delta
	rotation = velocity.angle()

func _on_timer_timeout():
	if !has_exploded:
		explode()

func explode():
	if has_exploded: return
	has_exploded = true	
	explosion_particles.emitting = true
	
	
	for i in shrapnel_amount:
			var shrapnel = shrapnel_scene.instantiate()
			shrapnel.position = global_position
			get_parent().add_child(shrapnel)
			# Apply random impulse
			shrapnel.apply_impulse(
				Vector2(randf_range(-200, 200), randf_range(-200, 0)),
				Vector2(randf_range(-20, 20), 0)
			)
	
	await get_tree().create_timer(explosion_particles.lifetime).timeout
	queue_free()



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("platform"):
		body.take_damage(2)
		explode()
	elif body.is_in_group("enemy"):
		body.take_damage(2, global_position)
		explode()
	elif body.name != "Player":
		explode()
