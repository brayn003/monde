@tool
class_name PlantBodyRender
extends Node2D

var _size_ratio = 1.0

var _size = Constants.PLANT_SIZE * _size_ratio
var radius = _size / 2.0

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.SADDLE_BROWN, false)
	
