@tool
class_name AikoBodyRender
extends CreatureBodyRender

var _body_radius = 0.0

func _init() -> void:
	_color = Constants.AIKO_COLOR
	_size = Constants.AIKO_SIZE
	_vision_angle = Constants.AIKO_VISION_ANGLE
	_body_radius = (0.7 * _size) / 2

func _draw_body() -> void:
	var tail_radius = (0.3 * _size) / 2
	
	var body_position = position
	var tail_position = Vector2(-(_body_radius + tail_radius), 0).rotated(rotation)

	draw_circle(body_position, _body_radius, _color, true)
	draw_circle(tail_position, tail_radius, _color, true)
	
func _draw_eyes() -> void:
	var eye_radius = 0.1 * _size
	var eye_positions = [
		Vector2(_body_radius, 0).rotated(rotation + (_vision_angle / 2)),
		Vector2(_body_radius, 0).rotated(rotation - (_vision_angle / 2)),
	]
	for eye_pos in eye_positions:
		draw_circle(eye_pos, eye_radius, Color.WHITE, true)
		draw_circle(eye_pos, 2, Color.BLACK, true)
	
func _draw() -> void:
	_draw_body()
	_draw_eyes()
