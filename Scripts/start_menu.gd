extends Control

@onready var start_button = $MarginContainer/VBoxContainer/StartButton
@onready var quit_button = $MarginContainer/VBoxContainer/QuitButton
@onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	print(Global.score)
	if Global.score != 0:
		var score = Global.score + int(Global.depth)
		score_label.text = "Score: %s" % score
		score_label.visible = true
	else:
		score_label.visible = false
	

func _on_start_pressed():
	Global.reset()
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_quit_pressed():
	get_tree().quit()
