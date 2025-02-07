@tool
class_name SlimeBody
extends Node2D

var size = Constants.SLIME_SIZE
var vision_angle = Constants.SLIME_VISION_ANGLE

var radius = size / 2
var eye_radius = 1.5

var trail_points: Array = []
var no_of_trail_points = 30

var is_first_draw = true

func draw_body() -> void:
	draw_circle(position, radius, Color.TURQUOISE, true)
	
func draw_eyes() -> void:
	var eye_positions = [
		Vector2.RIGHT.rotated(rotation + (vision_angle / 2)) * (radius - 4),
		Vector2.RIGHT.rotated(rotation + (-vision_angle / 2))  * (radius - 4),
	]
	draw_circle(eye_positions[0], eye_radius, Color.DARK_BLUE, true)
	draw_circle(eye_positions[1], eye_radius, Color.DARK_BLUE, true)
	
	
func _draw() -> void:
	if is_first_draw:
		is_first_draw = true
		draw_body()
		draw_eyes()
