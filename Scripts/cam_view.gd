@tool
extends ColorRect

func _ready() -> void:
	if Engine.is_editor_hint():
		size = Vector2(640,360)
		position = Vector2(-size.x / 2, -size.y / 2)
