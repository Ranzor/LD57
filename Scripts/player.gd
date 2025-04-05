extends CharacterBody2D

@export var health = 100
@export var speed = 80.0
@export var acceleration = 800.0
@export var friction = 1000.0
@export var jump_force = -160.0
@export var gravity = 400.0

@export var knockback_force = 400
@export var knockback_decay = 0

@export var LevelGenerator = Node2D

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

func _physics_process(delta: float) -> void:
	
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
		tiles_hit_this_attack.clear()
		is_attacking = true
		is_invincible = true
		animation.play("attack")
		animation.speed_scale = 1
		#fix hit box position

	 
	
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
		body.take_damage(1, global_position)
	
	# Get the sword's hitbox global rect (position + size)
	var hitbox_rect = $weapon_pivot/SwordHitBox/ColShape2D.shape.get_rect()
	hitbox_rect.position = $weapon_pivot/SwordHitBox.global_position

	# Convert rect to TileMapLayer's coordinate system
	var start_pos = tilemap.local_to_map(tilemap.to_local(hitbox_rect.position))
	var end_pos = tilemap.local_to_map(tilemap.to_local(hitbox_rect.end))

	# Iterate over all tiles in the hitbox area
	for x in range(start_pos.x, end_pos.x + 1):
		for y in range(start_pos.y, end_pos.y + 1):
			var tile_coords := Vector2i(x, y)
			
			if tilemap.get_cell_source_id(tile_coords) == -1:
				continue
			if tiles_hit_this_attack.has(tile_coords):
				continue
			
			tiles_hit_this_attack[tile_coords] = true
			tilemap.damage_tile(tile_coords)
			
func take_damage(enemy_global_pos: Vector2):
	if !is_invincible:
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.02).timeout
		Engine.time_scale = 1.0
		
		var dir_to_player = (global_position - enemy_global_pos).normalized()
		knockback = dir_to_player * knockback_force
		$Camera2D.apply_shake(0.8)
		
		health -= 10
		$Sprite2D.modulate = Color(2,2,2)
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.15)
		
		if health <= 10:
			die()

func die():
	queue_free()
