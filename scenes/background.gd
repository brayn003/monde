class_name BackgroundTrails
extends Node2D

var trails: Dictionary = {}
var trail_limit = 20

func draw_trails(bodies: Array) -> void:
	for body in bodies:
		if not is_instance_valid(body):
			trails.erase(body)
			continue
		if not trails.has(body):
			trails[body] = []
		
		var trail: Array = trails[body]
		if trail.size() >= trail_limit:
			trail.pop_front()
		trail.push_back(body.global_position)
	queue_redraw()
	
func _draw() -> void:
	for trail in trails.values():
		for i in trail.size():
			if i == 0:
				continue
			draw_line(trail[i - 1], trail[i], Color.ALICE_BLUE, 2)
			
			
	
