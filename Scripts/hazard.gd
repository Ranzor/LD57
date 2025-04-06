extends Area2D

@export var damage = 5
var biome_dirt = 3
var biome_cave = 7
var biome_lava = 11

var can_damage = true

@onready var sprite = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Timer.timeout.connect(_on_cooldown_end)
	
func _on_body_entered(body: Node) -> void:
	if can_damage && body.name == "Player":
		body.take_damage(global_position)
		can_damage = false
		$Timer.start(0.5)
		
func _on_cooldown_end() -> void:
	can_damage = true
	
	


func _on_area_entered(area: Area2D) -> void:
	queue_free()
	pass # Replace with function body.
