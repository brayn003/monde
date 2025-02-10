@tool
class_name SlimeBody
extends Node2D

var size = Constants.SLIME_SIZE
var vision_angle = Constants.SLIME_VISION_ANGLE

var head_radius = (0.5 * size) / 2
var body_radius = (0.3 * size) / 2
var tail_radius = (0.2 * size) / 2
var head_position = position
var body_position = Vector2(-(head_radius + body_radius), 0).rotated(rotation)
var tail_position = Vector2(-(head_radius + (2 * body_radius) + tail_radius), 0).rotated(rotation)
	
var eye_radius = 2

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func draw_body() -> void:
	draw_circle(head_position, head_radius, Color.TURQUOISE, true)
	draw_circle(body_position, body_radius, Color.TURQUOISE, true)
	draw_circle(tail_position, tail_radius, Color.TURQUOISE, true)
	
func draw_eyes() -> void:
	var eye_positions = [
		Vector2(head_radius, 0).rotated(rotation + (vision_angle / 2)),
		Vector2(head_radius, 0).rotated(rotation - (vision_angle / 2)),
	]
	for eye_pos in eye_positions:
		draw_circle(eye_pos, eye_radius, Color.WHITE, true)
		draw_circle(eye_pos, 1, Color.BLACK, true)
	
	
func _draw() -> void:
	draw_body()
	draw_eyes()
