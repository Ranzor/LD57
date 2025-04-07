extends StaticBody2D

@export var upgrade_type : Global.UPGRADES
@export var price : int

@export var icon : Sprite2D
@export var tens_place = Sprite2D
@export var ones_place : Sprite2D

@export var health_icon : Texture2D
@export var fireball_icon : Texture2D
@export var power_icon : Texture2D

var can_buy = false
var player = null

func _ready() -> void:
	print("Icon node ", icon)
	print("tens place ", tens_place)
	print("ones place ", ones_place)

func setup(type: Global.UPGRADES, cost: int):
	upgrade_type = type
	price = int(cost)
	var tens = price / 10
	var ones = price % 10
	
	match upgrade_type:
		Global.UPGRADES.HEALTH_BOOST:
			icon.texture = health_icon
			tens_place.frame = tens
			ones_place.frame = ones			
		Global.UPGRADES.POWER_BOOST:
			icon.texture = power_icon
			tens_place.frame = tens
			ones_place.frame = ones	
		Global.UPGRADES.FIREBALL:
			icon.texture = fireball_icon
			tens_place.frame = tens
			ones_place.frame = ones	
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		body.display_coin(price)
		can_buy = true
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.hide_coin()
		player = null
		can_buy = false


func _process(delta: float) -> void:
	if can_buy && Global.coins >= price:
		if Input.is_action_just_pressed("use"):
			apply_upgrade(player)
			pass

func apply_upgrade(player):
	Global.score += price
	Global.coins -= price
	match upgrade_type:
		Global.UPGRADES.HEALTH_BOOST:
			player.collect_health()
		Global.UPGRADES.POWER_BOOST:
			player.activate_power_boost(2,price)
		Global.UPGRADES.FIREBALL:
			player.fireball_unlocked = true
			player.fireball_count += 5
	if Global.coins < price: player.display_coin(price)
			
