class_name WorldBoundsRender
extends Node2D

func _draw() -> void:
	var rect_width = 4
	var top_rect = Rect2(
		Constants.WORLD_BOUND_LEFT.x - rect_width, 
		Constants.WORLD_BOUND_TOP.y, 
		Constants.WORLD_BOUND_RIGHT.x + 2 * rect_width, 
		-rect_width,
		)
	var right_rect = Rect2(
		Constants.WORLD_BOUND_RIGHT.x, 
		Constants.WORLD_BOUND_TOP.y - rect_width, 
		rect_width,
		Constants.WORLD_BOUND_BOTTOM.y + 2 * rect_width, 
		)
	var bottom_rect = Rect2(
		Constants.WORLD_BOUND_LEFT.x - rect_width, 
		Constants.WORLD_BOUND_BOTTOM.y, 
		Constants.WORLD_BOUND_RIGHT.x + 2 * rect_width, 
		rect_width,
		)
	var left_rect = Rect2(
		Constants.WORLD_BOUND_LEFT.x, 
		Constants.WORLD_BOUND_TOP.y - rect_width, 
		-rect_width,
		Constants.WORLD_BOUND_BOTTOM.y + 2 * rect_width, 
		)
	var rects = [top_rect, right_rect, bottom_rect, left_rect]
	for rect in rects:
		draw_rect(rect, Color.DIM_GRAY)
