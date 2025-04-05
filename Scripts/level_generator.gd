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

const MIN_X = WALL_LEFT + 1
const MAX_X = WALL_RIGHT - PLATFORM_WIDTH - 1

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

@onready var player = $"../Player"

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
	print("Generating")

func generate_initial_chunks():
	
	var start_depth = current_depth - (CHUNK_HEIGHT * 2)
	for i in range(5):
		current_depth = start_depth + (i * CHUNK_HEIGHT)
		generate_new_chunk()
	current_depth = start_depth + (5 * CHUNK_HEIGHT)

func generate_new_chunk():	
	if generated_chunks.size() >= MAX_CHUNKS * 2:
		return
	
	print("Generating chunk ", current_depth)
	
	for y in CHUNK_HEIGHT:
		var world_y = current_depth + y
		if tilemap_layer.get_cell_source_id(Vector2i(WALL_LEFT, world_y)) == -1:
			tilemap_layer.set_cell(Vector2i(WALL_LEFT, world_y), 0, WALL_TILE)
			tilemap_layer.set_cell(Vector2i(WALL_RIGHT, world_y), 0, WALL_TILE)
	
		if (world_y - current_depth) % PLATFORM_SPACING == 0:
			generate_platform(world_y)
				
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
	for x in length:
		var world_x = start_x + x
		if world_x >= WALL_RIGHT: break
		
		if randf() > GAP_CHANCE:
			tilemap_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
			
		if x == 0 || x == length-1:
			if randf() < 0.3:
				tilemap_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(1,0))

func create_full_platform(world_Y):
	var start = WALL_LEFT + 1
	var end = WALL_RIGHT - 1
	var has_gap = false
	
	for x in range(start ,end +1):
		if randf() < GAP_CHANCE and has_gap == false:
			has_gap = true
			continue
		else:
			has_gap = false
			
		if randf() < 0.85: # special tiles
			tilemap_layer.set_cell(Vector2i(x, world_Y), 0, Vector2i(0,0))


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
	

func clear_chunk(chunk_base: int):
	print("Clearing chunk ", chunk_base)
	
	for y in CHUNK_HEIGHT:
		var world_y = chunk_base + y
		for x in range(WALL_LEFT + 1, WALL_RIGHT):
			tilemap_layer.erase_cell(Vector2i(x,world_y))


func _process(delta):
	print("Active chunks: ", generated_chunks.size())
