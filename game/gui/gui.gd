class_name Gui
extends CanvasLayer

var focused_organism: Organism

@onready var current_stats = $TopRight/Stats/Container/Panel/Label
@onready var prev_gen_stats = $TopRight/PrevGen/Container/Panel/Label

@onready var organism_panel = $TopLeft/OrganismPanel
@onready var network_graph = $TopLeft/OrganismPanel/Container/Panel/HBoxContainer/Graph
@onready var organism_stats = $TopLeft/OrganismPanel/Container/Panel/HBoxContainer/Stats

@onready var map_inner_panel = $BottomRight/MapPanel/Container/Panel
@onready var map_vp = $BottomRight/MapPanel/Container/Panel/SubViewportContainer/SubViewport

var _world: World

func _ready() -> void:
	focus_on_organism(null)
	_ready_map_viewport()
	
func _ready_map_viewport() -> void:
	map_inner_panel.custom_minimum_size = Vector2(
		Constants.WORLD_BOUND_RIGHT.x / 20 + 10, 
		Constants.WORLD_BOUND_BOTTOM.y / 20 + 10)
	map_vp.size_2d_override = Vector2(
		Constants.WORLD_BOUND_RIGHT.x, 
		Constants.WORLD_BOUND_BOTTOM.y)
	map_vp.size_2d_override_stretch = true

func focus_on_organism(organism: Organism) -> void:
	organism_panel.visible = !!organism
	focused_organism = organism
	network_graph.focus_on_organism(organism)
	organism_stats.focus_on_organism(organism)
	

func _on_world_clock_tick(world: World) -> void:
	if not _world:
		map_vp.world_2d = get_viewport().world_2d
		_world = world
	
	var curr_fruit_count = get_tree().get_node_count_in_group("consumables")
	var max_fruit_count = Constants.MAX_FRUITS
	
	var curr_piki_count = get_tree().get_node_count_in_group("pikis")
	var max_piki_count = Constants.MAX_PIKIS
	var curr_piki_species_count = world.piki_ga.curr_species.values().size()
	var latest_piki_gen = world.curr_pikis[-1].generation if world.curr_pikis.size() > 0 else "-"
	
	var current_stats_text = ""
	current_stats_text += "Time: " + str(world.curr_clock_time) + "s"
	current_stats_text += "\nFrame Rate: " + str(Engine.get_frames_per_second()) + " fps"
	current_stats_text += "\nFruits: " + str(curr_fruit_count) + " / " + str(max_fruit_count)
	current_stats_text += "\n"
	current_stats_text += "\n[Piki] Population: " + str(curr_piki_count) + " / " + str(max_piki_count)
	current_stats_text += "\n[Piki] Species: " + str(curr_piki_species_count)
	current_stats_text += "\n[Piki] Latest Gen: " + str(latest_piki_gen)
	#current_stats_text += "\n--Aiko--"
	#current_stats_text += "\nAiko pop: " + str(world.curr_aikos.size())
	#current_stats_text += "\nAiko species: " + str(world.aiko_ga.curr_species.values().size())
	#current_stats_text += "\nCurrent Aiko Gen: " + str(world.aiko_ga.curr_generation) + " (" + str(world.generation_step) + "s)"
	current_stats.text = current_stats_text
	
	#var prev_gen_stats_text = ""
	#prev_gen_stats_text += "Gen: " + str(world.ga.curr_generation - 1)
	#prev_gen_stats_text += "\nNew species: " + str(world.ga.num_new_species)
	#prev_gen_stats_text += "\nDead species: " + str(world.ga.num_dead_species)
	#prev_gen_stats_text += "\nTotal species: " + str(world.ga.curr_species.values().size())
	#prev_gen_stats_text += "\nAvg fitness: " + str(snapped(world.ga.avg_population_fitness, 0.01))
	#prev_gen_stats_text += "\nBest fitness: " + str(snapped(world.ga.curr_best.fitness, 0.01) if world.ga.curr_best else "-")
	#prev_gen_stats.text = prev_gen_stats_text
