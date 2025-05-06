@tool
class_name PikiBodyRender
extends CreatureBodyRender

var _head_radius = (0.5 * _size) / 2

func _init() -> void:
	_color = Constants.PIKI_COLOR
	_size = Constants.PIKI_SIZE
	_vision_angle = Constants.PIKI_VISION_ANGLE

func draw_body() -> void:
	var body_radius = (0.3 * _size) / 2
	var tail_radius = (0.2 * _size) / 2
	
	var head_position = position
	var body_position = Vector2(-(_head_radius + body_radius), 0).rotated(rotation)
	var tail_position = Vector2(-(_head_radius + (2 * body_radius) + tail_radius), 0).rotated(rotation)

	draw_circle(head_position, _head_radius, _color, true)
	draw_circle(body_position, body_radius, _color, true)
	draw_circle(tail_position, tail_radius, _color, true)
	
func draw_eyes() -> void:
	var eye_radius = 0.1 * _size
	var eye_positions = [
		Vector2(_head_radius, 0).rotated(rotation + (_vision_angle / 2)),
		Vector2(_head_radius, 0).rotated(rotation - (_vision_angle / 2)),
	]
	for eye_pos in eye_positions:
		draw_circle(eye_pos, eye_radius, Color.WHITE, true)
		draw_circle(eye_pos, 0.5, Color.BLACK, true)
	
func _draw() -> void:
	draw_body()
	draw_eyes()
