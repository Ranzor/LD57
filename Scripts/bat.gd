extends CharacterBody2D

@export var health = 2
@export var speed = 40.0

var direction = -1
var can_turn = true
var is_staggered = false

@onready var animation = $AnimationPlayer
@onready var ypos = global_position.y

func _ready() -> void:
	animation.speed_scale = 0.3
	
func _physics_process(delta: float) -> void:
	global_position.y = ypos
	if !is_staggered:
		velocity.x = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_turn_around()
		
	if global_position.x <= -9 * 8:
		_turn_around()
	if global_position.x >= 9 * 8:
		_turn_around()
	
	#if can_turn and (is_on_wall() or _is_at_edge()):
	#	_turn_around()
func _is_at_edge() -> bool:
	return !$RayCastLeft.is_colliding() or !$RayCastRight.is_colliding()
	
func take_damage(amount : int, source_position: Vector2):
	
	if is_staggered: return
	is_staggered = true
	
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.02).timeout
	Engine.time_scale = 1.0
	
	health -= amount
	$Sprite2D.modulate = Color(3,0,0)
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.15)
	var knockback_dir = (global_position - source_position).normalized()
	velocity = knockback_dir * 200
	move_and_slide()
	await get_tree().create_timer(0.1).timeout
	is_staggered = false
	
	if health <= 0:
		die()
		
func die():
	queue_free()

func _turn_around():
	direction *= -1
	can_turn = false
	await get_tree().create_timer(0.5).timeout
	can_turn = true

func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(global_position)
