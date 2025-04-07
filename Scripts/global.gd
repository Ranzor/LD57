extends Node


var health = 100
var score = 0
var coins = 0
var max_depth = 4000
var fireball_count = 0
var depth = 0
var power_duration = 0
var power_time = 0

enum UPGRADES {HEALTH_BOOST, POWER_BOOST, FIREBALL}

const SHOP_DATA = {
	UPGRADES.HEALTH_BOOST: {"min_price": 10, "max_price": 20},
	UPGRADES.POWER_BOOST: {"min_price": 15, "max_price": 25},
	UPGRADES.FIREBALL: {"min_price": 10, "max_price": 30}
}

func reset():
	health = 100
	score = 0
	coins = 0
	fireball_count = 0
	depth = 0
	power_duration = 0
	power_time = 0
