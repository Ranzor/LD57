extends Camera2D

# Screen Shake Properties
@export var decay_rate = 1.5
@export var max_offset = Vector2(32,16)
@export var roll = true
@export var max_roll = 0.5

# Look Ahead Properties
@export var max_look_ahead = 600.0
@export var look_ahead_strength = 0.25
@export var smooth_speed = 5.0
@export var player_edge_margin = 90

var player: CharacterBody2D
var base_offset := Vector2.ZERO
var trauma = 0.0
var trauma_power = 2.5

func _ready() -> void:
	randomize()
	player = get_tree().get_first_node_in_group("player")
	base_offset = offset

func _process(delta: float) -> void:
	if position.y < -100: position.y = -100
	if !player:
		return
	
	# Handle both systems
	_apply_look_ahead(delta)
	_apply_shake()
	
	# Keep these separate from position modifications
	if trauma > 0:
		trauma = max(trauma - decay_rate * delta, 0)

func _apply_look_ahead(delta):
	# Get viewport dimensions
	var viewport = get_viewport_rect().size * zoom
	
	# Calculate vertical look-ahead
	var velocity_offset = Vector2.ZERO
	if player.velocity.y > 0:  # Moving downward
		velocity_offset.y = clamp(
			player.velocity.y * look_ahead_strength, 
			0, 
			max_look_ahead
		)
	
	# Calculate target position
	var target_position = player.global_position + base_offset + velocity_offset
	
	# Keep player within viewable area
	var camera_bottom = global_position.y + viewport.y/2
	var player_bottom = player.global_position.y + player_edge_margin
	
	if player_bottom > camera_bottom:
		target_position.y += player_bottom - camera_bottom
	
	# Apply look-ahead without affecting final position
	var new_position = global_position.lerp(
		Vector2(global_position.x, target_position.y), 
		smooth_speed * delta
	)
	
	# Set position but keep available for shake
	global_position = new_position

func _apply_shake():
	var amount = pow(trauma, trauma_power)
	offset = Vector2(
		max_offset.x * amount * randf_range(-1,1),
		max_offset.y * amount * randf_range(-1,1)
	)
	
	if roll:
		rotation = max_roll * amount * randf_range(-1,1)

func apply_shake(intensity = 0.5):
	trauma = min(trauma + intensity, 1.0)
