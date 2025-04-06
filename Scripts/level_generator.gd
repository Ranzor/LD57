extends Node2D

const CHUNK_HEIGHT = 50
const LOAD_THRESHOLD = 100
const MAX_CHUNKS = 5
const PLATFORM_WIDTH = 4
const WALL_TILE = Vector2i(2,0)
const PLATFORM_TILE = Vector2i(0,0)
const WALL_LEFT = -10
const WALL_RIGHT = 10
const MIN_PLATFORM_LENGTH = 6
const MAX_PLATFORM_LENGTH = 19
const LAYER_ID = 0
const EDGE_CHANCE = 0.4
const GAP_CHANCE = 0.15
const PLATFORM_SPACING = 3
const LOAD_AHEAD = 3
const TILE_SIZE = 8
const MAX_FALL_SPEED = 1500

const DIRT_DEPTH = 500
const CAVE_DEPTH = 1000
const LAVA_DEPTH = 1500
const HAZARD_CHANCE = 0.3



const MIN_SPAWN_DEPTH = 200
const MAX_SPAWN_DEPTH = 1500
const SPAWN_PADDING = 32


const MIN_X = WALL_LEFT + 1
const MAX_X = WALL_RIGHT - PLATFORM_WIDTH - 1

var	BASE_SPAWN_CHANCE = 0.10
var ENEMY_SPAWN_CHANCE = 0.10
var BASE_MAX_ENEMIES = 3.0
var MAX_ENEMIES_PER_CHUNK = 3.0



var current_depth = 0
var platform_x = 0
var tilemap_layer : TileMapLayer
var tileset = preload("res://dirttiles.tres")
var direction_bias = 0
var last_platform_x = 0
var last_platform_right = 0
var last_platform_left = 0
var current_wall_height = 0
var cleanup_depth = 0
var generation_queue = 0
var current_chunk_enemies = 0

@onready var player = $"../Player"
@export var worm_scene : PackedScene
@export var bat_scene : PackedScene
@export var frog_scene : PackedScene
@export var hazard_scene : PackedScene
@export var platform_scene : PackedScene

@export var easy_weight_curve : Curve
@export var medium_weight_curve : Curve
@export var hard_weight_curve : Curve

var generated_chunks = []
var current_chunk_y = 0

func _ready() -> void:
	randomize()
	randomize()
	randomize()
	
	tilemap_layer = TileMapLayer.new()
	tilemap_layer.set_name("MainLayer")
	tilemap_layer.add_to_group("tiles")
	tilemap_layer.set_script(load("res://Scripts/tile_map_layer.gd"))
	tilemap_layer.tile_set = tileset
	add_child(tilemap_layer)
	
	current_depth = int(player.global_position.y / TILE_SIZE)
	generate_initial_chunks()

func generate_initial_chunks():
	
	var start_depth = current_depth - (CHUNK_HEIGHT * 2)
	for i in range(5):
		current_depth = start_depth + (i * CHUNK_HEIGHT)
		generate_new_chunk()
	current_depth = start_depth + (5 * CHUNK_HEIGHT)

func generate_new_chunk():	
	print(current_depth)
	current_chunk_enemies = 0
	if generated_chunks.size() >= MAX_CHUNKS * 2:
		return
	
	for y in CHUNK_HEIGHT:
		var biome_y = get_biome_y_offset(current_depth)
		var world_y = current_depth + y
		if tilemap_layer.get_cell_source_id(Vector2i(WALL_LEFT, world_y)) == -1:
			tilemap_layer.set_cell(Vector2i(WALL_LEFT, world_y), 0, Vector2i(2, biome_y))
			tilemap_layer.set_cell(Vector2i(WALL_RIGHT, world_y), 0, Vector2i(2, biome_y))
	
		if (world_y - current_depth) % PLATFORM_SPACING == 0:
			generate_platform(world_y)
				
	update_difficulty()
	current_depth += CHUNK_HEIGHT
	generated_chunks.append(current_chunk_y)
	
func generate_platform(world_y : int):
	var platform_type = randi() % 3
	
	match platform_type:
		0:
			var length = randi_range(MIN_PLATFORM_LENGTH, MAX_PLATFORM_LENGTH)
			create_platform_segment(WALL_LEFT + 1, length, world_y)
		1:
			var length = randi_range(MIN_PLATFORM_LENGTH, MAX_PLATFORM_LENGTH)
			create_platform_segment(WALL_RIGHT - length, length, world_y)
		2:
			create_full_platform(world_y)
	
func create_platform_segment(start_x : int, length: int, world_y: int):
	var biome_y = get_biome_y_offset(current_depth)
	var platform_count = 0
	
	for x in length:
		var world_x = start_x + x
		if world_x >= WALL_RIGHT: break
		
		if randf() < GAP_CHANCE:			
			if randf() < HAZARD_CHANCE && current_depth > MIN_SPAWN_DEPTH:
				spawn_hazard(world_x, world_y, biome_y)
			continue
			
		var platform = platform_scene.instantiate()
		platform.global_position = tilemap_layer.map_to_local(Vector2i(world_x, world_y))
		platform.set_biome(biome_y)
		add_child(platform)
		platform_count += 1
				
				
		if platform_count >= MIN_PLATFORM_LENGTH:
			if x == length / 2:
				try_spawn_enemy(world_x, world_y -1)

func create_full_platform(world_y):
	var biome_y = get_biome_y_offset(current_depth)
	var start = WALL_LEFT + 1
	var end = WALL_RIGHT - 1
	var has_gap = false
	
	for x in range(start ,end +1):
		if randf() < GAP_CHANCE and has_gap == false:
			has_gap = true
			continue
		else:
			has_gap = false
			
		if randf() < 0.85:
			var platform = platform_scene.instantiate()
			platform.global_position = tilemap_layer.map_to_local(Vector2i(x,world_y))
			platform.set_biome(biome_y)
			add_child(platform)
			#tilemap_layer.set_cell(Vector2i(x, world_y), 0, Vector2i(0,biome_y))
			
		if (end - start) >= MIN_PLATFORM_LENGTH:
			var spawn_x = start + (end - start) / 2
			try_spawn_enemy(spawn_x, world_y -1)


func cleanup_old_chunks():
	var player_y = player.global_position.y
	var cleanup_threashold = player_y - (MAX_CHUNKS * CHUNK_HEIGHT * tilemap_layer.rendering_quadrant_size)
	
	while generated_chunks.size() > 0 && generated_chunks[0] < cleanup_threashold:
		var oldest_chunk = generated_chunks.pop_front()
		for y in CHUNK_HEIGHT:
			var world_y = oldest_chunk + y
			for x in range(WALL_LEFT + 1, WALL_RIGHT):
				tilemap_layer.erase_cell(Vector2i(x, world_y))
	
func _physics_process(delta: float) -> void:
	var player_y = player.global_position.y
	var player_tile_y = int(player_y / TILE_SIZE)

	var load_bottom = player_tile_y + (LOAD_AHEAD * CHUNK_HEIGHT)
	var chunks_needed = int(max(0, (load_bottom - current_depth) / CHUNK_HEIGHT))
	
	for i in range(min(chunks_needed, 2)):
		generate_new_chunk()
		
	var cleanup_top = player_tile_y - (MAX_CHUNKS * CHUNK_HEIGHT)
	while generated_chunks.size() > 0 && generated_chunks[0] < cleanup_top:
		clear_chunk(generated_chunks.pop_front())
		
	MAX_ENEMIES_PER_CHUNK += current_depth * 0.00005
	ENEMY_SPAWN_CHANCE += get_biome_y_offset(current_depth) * 0.1
	

func clear_chunk(chunk_base: int):
	for y in CHUNK_HEIGHT:
		var world_y = chunk_base + y
		for x in range(WALL_LEFT + 1, WALL_RIGHT):
			tilemap_layer.erase_cell(Vector2i(x,world_y))

func try_spawn_enemy(world_x : int, world_y: int):
	if current_chunk_enemies >= MAX_ENEMIES_PER_CHUNK:
		return				
	var current_depth_px = abs(world_y * TILE_SIZE)
	if current_depth_px < MIN_SPAWN_DEPTH:
		return
	
	var depth_normalized = clamp(
		(current_depth_px - MIN_SPAWN_DEPTH) /
		(MAX_SPAWN_DEPTH - MIN_SPAWN_DEPTH),
		0.0, 1.0
	)
	
	var weights = {
		worm_scene: easy_weight_curve.sample(depth_normalized),
		bat_scene: medium_weight_curve.sample(depth_normalized),
		frog_scene: hard_weight_curve.sample(depth_normalized)
	}
	
	var enemy_scene = weighted_random(weights)
	if !enemy_scene:
		return
		
	var spawn_pos = tilemap_layer.map_to_local(Vector2i(world_x,world_y))
	if spawn_pos.distance_to(player.global_position) < SPAWN_PADDING:
		return
		
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(spawn_pos) < TILE_SIZE * 2:
			return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	add_child(enemy)
	current_chunk_enemies += 1
	
func weighted_random(weights: Dictionary):
	var total = 0.0
	for key in weights:
		total += weights[key]
		
	if total <= 0:
		return null
	
	var roll = randf_range(0.0, total)
	var current = 0.0
	
	for key in weights:
		current += weights[key]
		if roll <= current:
			return key
	return null
	
func get_biome_y_offset(current_depth : float) -> int:
	if current_depth < DIRT_DEPTH:
		return 0
	elif current_depth < CAVE_DEPTH:
		return 1
	else:
		return 2
		
func spawn_hazard(x : int, y : int, biome: int):
	var hazard = hazard_scene.instantiate()
	hazard.global_position = tilemap_layer.map_to_local(Vector2i(x,y))
	add_child(hazard)
	match biome:
		0:
			hazard.sprite.frame = hazard.biome_dirt
		1:
			hazard.sprite.frame = hazard.biome_cave
		2:
			hazard.sprite.frame = hazard.biome_lava
			
func update_difficulty():
	var factor = log(current_depth / 500.0 + 1)  # Logarithmic scaling; adjust constants as needed
	ENEMY_SPAWN_CHANCE = clamp(BASE_SPAWN_CHANCE + factor * 0.05, 0.10, 0.5)
	MAX_ENEMIES_PER_CHUNK = clamp(BASE_MAX_ENEMIES + factor * 2.0, 3.0, 10.0)
