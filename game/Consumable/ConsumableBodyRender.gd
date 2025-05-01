@tool
class_name ConsumableBodyRender
extends Node2D

var radius = 0.0

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.FIREBRICK, true)
