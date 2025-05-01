class_name Gui
extends CanvasLayer

var focused_organism: Organism

@onready var current_stats = $TopRight/Stats/Container/Panel/Label
@onready var prev_gen_stats = $TopRight/PrevGen/Container/Panel/Label

@onready var organism_panel = $TopLeft/OrganismPanel
@onready var network_graph = $TopLeft/OrganismPanel/Container/Panel/HBoxContainer/Graph
@onready var organism_stats = $TopLeft/OrganismPanel/Container/Panel/HBoxContainer/Stats

func _ready() -> void:
	focus_on_organism(null)

func focus_on_organism(organism: Organism) -> void:
	organism_panel.visible = !!organism
	focused_organism = organism
	network_graph.focus_on_organism(organism)
	organism_stats.focus_on_organism(organism)
	

func _on_world_clock_tick(world: World) -> void:
	var current_stats_text = ""
	current_stats_text += "Population: " + str(world.curr_slimes.size())
	current_stats_text += "\nTime: " + str(world.curr_clock_time) + "s"
	current_stats_text += "\nCurrent Gen: " + str(world.ga.curr_generation) + " (" + str(world.generation_step) + "s)"
	current_stats.text = current_stats_text
	
	var prev_gen_stats_text = ""
	prev_gen_stats_text += "Gen: " + str(world.ga.curr_generation - 1)
	prev_gen_stats_text += "\nNew species: " + str(world.ga.num_new_species)
	prev_gen_stats_text += "\nDead species: " + str(world.ga.num_dead_species)
	prev_gen_stats_text += "\nTotal species: " + str(world.ga.curr_species.values().size())
	prev_gen_stats_text += "\nAvg fitness: " + str(snapped(world.ga.avg_population_fitness, 0.01))
	prev_gen_stats_text += "\nBest fitness: " + str(snapped(world.ga.curr_best.fitness, 0.01) if world.ga.curr_best else "-")
	prev_gen_stats.text = prev_gen_stats_text
