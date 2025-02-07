@tool

extends Node2D

var radius = Constants.FOOD_SIZE / 2

func _draw() -> void:
	draw_circle(position, radius, Color.ORANGE_RED, true)
	
