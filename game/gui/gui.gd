class_name Gui
extends CanvasLayer

signal clicked_build_spawner(family: Constants.Family)

var _selected_entity: Creature = null

@onready var _current_stats = $TopRight/Stats/Container/Panel/Label
#@onready var _prev_gen_stats = $TopRight/PrevGen/Container/Panel/Label

@onready var _creature_panel = $BottomLeft/CreaturePanel
@onready var _creature_graph = $BottomLeft/CreaturePanel/Container/Panel/HBoxContainer/Graph
@onready var _creature_stats = $BottomLeft/CreaturePanel/Container/Panel/HBoxContainer/Stats

@onready var _map_inner_panel = $BottomRight/MapPanel/Container/Panel
@onready var _map_viewport = $BottomRight/MapPanel/Container/Panel/SubViewportContainer/SubViewport

func _ready() -> void:
	_ready_map_viewport()

func _ready_map_viewport() -> void:
	_map_inner_panel.custom_minimum_size = Vector2(
		Constants.WORLD_BOUND_RIGHT.x / 20 + 10, 
		Constants.WORLD_BOUND_BOTTOM.y / 20 + 10)
	_map_viewport.size_2d_override = Vector2(
		Constants.WORLD_BOUND_RIGHT.x, 
		Constants.WORLD_BOUND_BOTTOM.y)
	_map_viewport.size_2d_override_stretch = true
	_map_viewport.world_2d = get_viewport().world_2d

func _on_world_clock_tick(world: World) -> void:
	var curr_fruit_count = get_tree().get_node_count_in_group("consumables")
	var max_fruit_count = Constants.MAX_FRUITS
	
	var curr_pikis = get_tree().get_nodes_in_group("pikis")
	var curr_piki_count = curr_pikis.size()
	var piki_ga = world._ga[Constants.Family.PIKI]
	var curr_piki_species_count = piki_ga._curr_species.size()
	var max_piki_count = Constants.MAX_PIKIS
	var curr_best_piki_fitness = snapped(piki_ga._curr_best_genome.fitness, 0.01) if piki_ga._curr_best_genome else "-"
	var curr_piki_avg_fitness = snapped(piki_ga._avg_population_fitness, 0.01)
	var latest_piki_gen = piki_ga._curr_genomes[-1].generation if piki_ga._curr_genomes.size() > 0 else "-"
	var total_piki_spawns = piki_ga._curr_genome_id
	
	var current_stats_text = ""
	current_stats_text += "Time: " + str(world.curr_time) + "s"
	current_stats_text += "\nFrame Rate: " + str(Engine.get_frames_per_second()) + " fps"
	current_stats_text += "\nFruits: " + str(curr_fruit_count) + " / " + str(max_fruit_count)
	current_stats_text += "\n"
	current_stats_text += "\n[Piki] Population: " + str(curr_piki_count) + " / " + str(max_piki_count)
	current_stats_text += "\n[Piki] Species: " + str(curr_piki_species_count)
	current_stats_text += "\n[Piki] Avg Fitness: " + str(curr_piki_avg_fitness)
	current_stats_text += "\n[Piki] Best Fitness: " + str(curr_best_piki_fitness)
	current_stats_text += "\n[Piki] Latest Gen: " + str(latest_piki_gen)
	current_stats_text += "\n[Piki] Total Spawns: " + str(total_piki_spawns)
	#current_stats_text += "\n--Aiko--"
	#current_stats_text += "\nAiko pop: " + str(world.curr_aikos.size())
	#current_stats_text += "\nAiko species: " + str(world.aiko_ga.curr_species.values().size())
	#current_stats_text += "\nCurrent Aiko Gen: " + str(world.aiko_ga.curr_generation) + " (" + str(world.generation_step) + "s)"
	_current_stats.text = current_stats_text
	
	#var prev_gen_stats_text = ""
	#prev_gen_stats_text += "Gen: " + str(world.ga.curr_generation - 1)
	#prev_gen_stats_text += "\nNew species: " + str(world.ga.num_new_species)
	#prev_gen_stats_text += "\nDead species: " + str(world.ga.num_dead_species)
	#prev_gen_stats_text += "\nTotal species: " + str(world.ga.curr_species.values().size())
	#prev_gen_stats_text += "\nAvg fitness: " + str(snapped(world.ga.avg_population_fitness, 0.01))
	#prev_gen_stats_text += "\nBest fitness: " + str(snapped(world.ga.curr_best.fitness, 0.01) if world.ga.curr_best else "-")
	#_prev_gen_stats.text = prev_gen_stats_text

func _on_world_select_entity(creature: Creature) -> void:
	_creature_panel.visible = !!creature
	_selected_entity = creature
	_creature_graph.select_entity(creature)
	_creature_stats.select_entity(creature)
