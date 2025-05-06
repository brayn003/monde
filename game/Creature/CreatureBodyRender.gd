@tool
class_name CreatureBodyRender
extends Node2D

var _color = Color.ROYAL_BLUE
var _size = 10.0
var _radius = _size / 2

var _vision_angle = (TAU) / 3  # 180 deg

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw_body() -> void:
	draw_circle(position, _radius, _color, true)

func _draw_eyes() -> void:
	var eye_radius = 0.4 * _radius
	var eye_positions = [
		Vector2(_radius, 0).rotated(rotation + (_vision_angle / 2)),
		Vector2(_radius, 0).rotated(rotation - (_vision_angle / 2)),
	]
	for eye_pos in eye_positions:
		draw_circle(eye_pos, eye_radius, Color.WHITE, true)
		draw_circle(eye_pos, 1, Color.BLACK, true)

func _draw() -> void:
	_draw_body()
	_draw_eyes()
