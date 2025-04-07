extends CharacterBody2D

@export var normal : Texture
@export var power : Texture

@export var health = 100
@export var speed = 80.0
@export var acceleration = 800.0
@export var friction = 1000.0
@export var jump_force = -160.0
@export var gravity = 400.0

@export var knockback_force = 500
@export var knockback_decay = 0

@export var LevelGenerator = Node2D


@export var trail_interval = 0.1
@export var trail_color = Color(1,1,1,0.5)
@export var trail_texture : Texture2D
@export var damage_cooldown = 1.0


@export var min_light_energy := 0.0
@export var max_light_energy := 1.0
@export var min_light_range := 200.0
@export var max_light_range := 400.0

@export var coin_symbol : Sprite2D
@export var no_coin_symbol : Sprite2D

@export var jumpSound : AudioStreamWAV
@export var audioPlayer : AudioStreamPlayer2D
@export var hitHurt : AudioStreamWAV
@export var powerUp : AudioStreamWAV
@export var swordSwing : AudioStreamWAV
@export var pickupCoin : AudioStreamWAV
@export var hpUp : AudioStreamWAV


var power_boost_active = false
var power_boost_timer : Timer

var current_damage = 2
var base_damage = 2

var fireball_unlocked = false
var fireball_count = 0

var last_damage_time = 0.0
var hazard_tiles = [
	Vector2i(3,0),	# Dirt Spikes
	Vector2i(3,1),	# Cave Spikes
	Vector2i(3,2)	# Lava Spikes
]


var trail_timer = 0.0
var trail_scene = preload("res://Scenes/ghost_trail.tscn")

var knockback = Vector2.ZERO

var current_depth = 0.0
var last_chunk_y = 0.0
var chunk_size = 100



var coyote_time = false
var jump_buffer = false
var can_double_jump = false
var tiles_hit_this_attack = {}
var is_attacking = false
var is_invincible = false

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var tilemap : TileMapLayer = get_tree().get_first_node_in_group("tiles")




func _ready() -> void:
	animation.speed_scale = 0.1
	$weapon_pivot/SwordHitBox/ColShape2D.disabled = true
	
	power_boost_timer = Timer.new()
	power_boost_timer.one_shot = true
	power_boost_timer.timeout.connect(_end_power_boost)
	add_child(power_boost_timer)

func _physics_process(delta: float) -> void:
	
	Global.health = health
	Global.fireball_count = fireball_count
	Global.power_time = power_boost_timer.time_left
	
	if position.y > Global.depth: Global.depth = position.y
	trail_timer += delta
	if trail_timer >= trail_interval:
		spawn_trail()
		trail_timer = 0.0
	
	current_depth = max(current_depth, abs(position.y))
	
	if position.y < last_chunk_y - chunk_size:
		#spawn_new_chunk()
		pass
	
	velocity += knockback
	knockback *= knockback_decay
	
	if !is_attacking:
		handle_movement(delta)
		handle_jump()
		
	apply_gravity(delta)
	handle_animations()
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") && !is_attacking:
		audioPlayer.stream = swordSwing
		audioPlayer.play()
		tiles_hit_this_attack.clear()
		is_attacking = true
		is_invincible = true
		animation.play("attack")
		animation.speed_scale = 3
		#fix hit box position
	
	if event.is_action_pressed("fire"):
		if fireball_unlocked && fireball_count >= 1:
			throw_fireball()
			fireball_count -= 1
			if fireball_count <= 0:
				fireball_unlocked = false

	 
	
func handle_movement(delta):
	var input = Input.get_axis("move_left", "move_right")
	
	if input != 0:
		velocity.x = move_toward(velocity.x, input * speed, acceleration * delta)
		sprite.flip_h = input < 0
		$weapon_pivot.scale.x = -1 if input < 0 else 1
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_jump():
	if is_on_floor():
		can_double_jump = true
		coyote_time = true
		$CoyoteTime.start()
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer = true
		$JumpBuffer.start()
		audioPlayer.stream = jumpSound
		audioPlayer.play()
	
	if (coyote_time || is_on_floor()) && jump_buffer:
		perform_jump()
		
	elif can_double_jump && Input.is_action_just_pressed("jump"):
		perform_jump()
		can_double_jump = false
		
func perform_jump():
	velocity.y = jump_force
	coyote_time = false
	jump_buffer = false
	
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		



func _on_coyote_time_timeout() -> void:
	coyote_time = false


func _on_jump_buffer_timeout() -> void:
	jump_buffer = false
	
	
	
func handle_animations():
	if is_attacking: return
	
	if is_on_floor():
		if abs(velocity.x) > 10:
			animation.play("run")
			animation.speed_scale = 1
		else:
			animation.play("idle")
			animation.speed_scale = .1
			
	else:
		if velocity.y < 0:
			animation.play("jump")
		else:
			animation.play("fall")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		is_attacking = false
		is_invincible = false

func _on_sword_hit_box_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("enemy"):
		body.take_damage(current_damage, global_position)
		$"../Camera2D".apply_shake(.2)
	elif body.is_in_group("platform"):
		body.take_damage(current_damage/2)
		$"../Camera2D".apply_shake(.1)
			
func take_damage(amount : int, enemy_global_pos: Vector2):
	if !is_invincible:
		audioPlayer.stream = hitHurt
		audioPlayer.play()
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.02).timeout
		Engine.time_scale = 1.0
		
		var dir_to_player = (global_position - enemy_global_pos).normalized()
		knockback = dir_to_player * knockback_force
		$"../Camera2D".apply_shake(1.0)
		
		health -= amount
		$Sprite2D.modulate = Color(2,2,2)
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.15)
		
		if health <= 0:
			die()

func spawn_trail():
	var trail = trail_scene.instantiate()
	trail.texture = $Sprite2D.texture
	trail.frame = $Sprite2D.frame
	trail.global_position = global_position
	trail.modulate = trail_color
	trail.flip_h = $Sprite2D.flip_h
	get_parent().add_child(trail)

func collect_coin() -> void:
	Global.coins += 1
	audioPlayer.stream = pickupCoin
	audioPlayer.play()
		
func collect_health() -> void:
	audioPlayer.stream = hpUp
	audioPlayer.play()
	health += 20
		
func throw_fireball():
	var fireball = preload("res://Scenes/fireball.tscn").instantiate()
	fireball.global_position = global_position
	fireball.direction = 1 if !$Sprite2D.flip_h else -1
	get_parent().add_child(fireball)
	$"../Camera2D".apply_shake(.5)
		

func activate_power_boost(multiplier: float, duration : float):
	current_damage = base_damage * multiplier
	power_boost_active = true
	audioPlayer.stream = powerUp
	audioPlayer.play()
	$Sprite2D.texture = power
	
	if power_boost_timer.time_left > 0:
		power_boost_timer.stop()
	
	power_boost_timer.start(duration)
	Global.power_duration = duration
func _end_power_boost():
	current_damage = base_damage
	power_boost_active = false
	$Sprite2D.texture = normal
	
func update_light_for_darkness(darkness: float):
	$PointLight2D.energy = lerp(min_light_energy, max_light_energy, darkness)
	$PointLight2D.height = lerp(min_light_range, max_light_range, darkness)
	
	$PointLight2D.color.s = 1.0 - darkness * 0.5

func display_coin(cost : int):
	if Global.coins >= cost:
		coin_symbol.visible = true
		no_coin_symbol.visible = false
	else:
		coin_symbol.visible = false
		no_coin_symbol.visible = true
		
func hide_coin():
	coin_symbol.visible = false
	no_coin_symbol.visible = false

func die():
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
