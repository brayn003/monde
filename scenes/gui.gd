extends CanvasLayer

func _on_world_clock_tick(world: World) -> void:
	var stats_text = "Time: " + str(world.curr_clock_time) +"s"
	stats_text += "\nGen: " + str(world.ga.curr_generation) 
	stats_text += "\nGen Step: " + str(world.generation_step)
	$Stats/MarginContainer/Stats.text = stats_text


func _on_world_gen_tick(_world: World) -> void:
	var food_eaten = World.MAX_FOOD - get_tree().get_node_count_in_group("food")
	print(food_eaten,get_tree().get_node_count_in_group("food"))
	#$Stats/MarginContainer/WorldChart.plot_fn.add_point(
		#world.ga.curr_generation,
		#food_eaten,
	#)
	#$Stats/MarginContainer/WorldChart.chart.queue_redraw()
