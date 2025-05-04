class_name World
extends Node2D

"""This demo shows how to evolve arcade-style cars to successfully complete a track.
This is accomplished by assigning fitness based on how many degrees around the track
a car has driven, and regularly starting a new generation where the fittest individuals
are more prevalent.

New generations are started based on a timer (generation_step), because a lot of
cars end up just loitering around the track, and I haven't implemented a method
to detect this yet. This may cause successful agents to be stopped prematurely however.
"""

const piki_scene: Resource = preload("res://game/beasts/Piki/Piki.tscn")
const aiko_scene: Resource = preload("res://game/beasts/Aiko/Aiko.tscn")

const INITIAL_PIKIS = 100
const INITIAL_AIKOS = 40

signal clock_tick(world: World)
signal gen_tick(world: World)

@onready var SPAWN_MIN = Vector2(Constants.WORLD_BOUND_LEFT.x, Constants.WORLD_BOUND_TOP.y)
@onready var SPAWN_MAX = Vector2(Constants.WORLD_BOUND_RIGHT.x, Constants.WORLD_BOUND_BOTTOM.y)

var clock: Timer
var curr_clock_time: int = 0
var time_since_last_gen: int = 0
# every generation_step a new generation is made. this gets increased over time.
var generation_step: int = 60

# fitness treshold is 100 secs
var fitness_threshold = 100

var curr_pikis = []
var curr_aikos = []

@onready var piki_ga: GeneticAlgorithm = GeneticAlgorithm.new(9, 2, "res://game/Piki/Piki.tscn")
#@onready var aiko_ga: GeneticAlgorithm = GeneticAlgorithm.new(6, 4, "res://game/Aiko/Aiko.tscn")

@onready var gui: Gui = $"../Gui"
@onready var camera: Camera = $"../Camera"
@onready var terrain: Terrain = $Terrain

func _ready() -> void:
	#_create_planet()
	add_child(piki_ga)
	#add_child(aiko_ga)
	_spawn_initial_pikis()
	#_spawn_initial_aikos()
	_start_clock()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		gui.focus_on_organism(null)
		camera.focus_on_organism(null)

#region pikis
func _on_piki_death(piki: Piki) -> void:
	piki_ga.free_genome(piki.genome)
	curr_pikis.erase(piki)
	piki.queue_free()
	if gui.focused_organism == piki:
		gui.focus_on_organism(curr_pikis[-1] if curr_pikis.size() > 0 else null)
	if camera.focused_organism == piki:
		camera.focus_on_organism(curr_pikis[-1] if curr_pikis.size() > 0 else null)

func _on_piki_spawn(parent_piki: Piki) -> void:
	var genome = piki_ga.create_upgraded_genome(parent_piki.genome)
	create_piki(genome, parent_piki.body.position, random_angle(), parent_piki.generation)
	
func _on_piki_clicked(piki: Piki) -> void:
	gui.focus_on_organism(piki)
	camera.focus_on_organism(piki)

func create_piki(
	genome: Genome, 
	pos: Vector2 = Vector2(0, 0), 
	_rotation: float = 0,
	_prev_gen: int = 0
	) -> void:
	var piki: Piki = piki_scene.instantiate()
	piki.generation = _prev_gen + 1
	piki.add_genome(genome)
	piki.death.connect(_on_piki_death)
	piki.spawn.connect(_on_piki_spawn)
	piki.clicked.connect(_on_piki_clicked)
	add_child(piki)
	piki.body.position = pos
	piki.body.rotation = _rotation
	curr_pikis.append(piki)
	piki.add_to_group("pikis")

func _spawn_initial_pikis() -> void:
	for i in INITIAL_PIKIS:
		var genome = piki_ga.create_base_genome()
		create_piki(genome, random_pos(SPAWN_MIN, SPAWN_MAX), random_angle())

#endregion

#region aiko

#func _on_aiko_death(aiko: Aiko) -> void:
	#aiko_ga.free_genome(aiko.genome)
	#curr_aikos.erase(aiko)
	#aiko.queue_free()
	#if gui.focused_organism == aiko:
		#gui.focus_on_organism(curr_aikos[0] if curr_aikos.size() > 0 else null)
	#if camera.focused_organism == aiko:
		#camera.focus_on_organism(curr_aikos[0] if curr_aikos.size() > 0 else null)
#
#func _on_aiko_spawn(parent_aiko: Aiko) -> void:
	#if curr_aikos.size() >= MAX_BEASTS:
		#return
	#var genome = aiko_ga.create_upgraded_genome(parent_aiko.genome)
	#create_aiko(genome, parent_aiko.body.position, random_angle(), parent_aiko.generation)
	#
#func _on_aiko_clicked(aiko: Aiko) -> void:
	#gui.focus_on_organism(aiko)
	#camera.focus_on_organism(aiko)
#
#func create_aiko(
	#genome: Genome, 
	#pos: Vector2 = Vector2(0, 0), 
	#_rotation: float = 0,
	#_prev_gen: int = 0
	#) -> void:
	#var aiko: Aiko = aiko_scene.instantiate()
	#aiko.generation = _prev_gen + 1
	#aiko.add_genome(genome)
	#aiko.death.connect(_on_aiko_death)
	#aiko.spawn.connect(_on_aiko_spawn)
	#aiko.clicked.connect(_on_aiko_clicked)
	#add_child(aiko)
	#aiko.body.position = pos
	#aiko.body.rotation = _rotation
	#curr_aikos.append(aiko)
#
#func _spawn_initial_aikos() -> void:
	#for i in INITIAL_AIKOS:
		#var genome = aiko_ga.create_base_genome()
		#create_aiko(genome, random_pos(AIKO_SPAWN_MIN, AIKO_SPAWN_MAX), random_angle())

#endregion
#
#region clock
func _start_clock():
	clock = Timer.new()
	add_child(clock)
	clock.wait_time = 1.0
	clock.timeout.connect(_on_clock_time_step)
	clock.start()

func _on_clock_time_step() -> void:
	curr_clock_time += 1
	clock_tick.emit(self)
	
	terrain.generate_fruits()
	
	if curr_clock_time % generation_step == 0:
		gen_tick.emit(self)
		time_since_last_gen = 0
		
		var highest_piki_age = 0.0
		for piki in curr_pikis:
			highest_piki_age = maxf(highest_piki_age, piki.calc_age())
		piki_ga.evaluate_generation()
		piki_ga.curr_generation += 1
		
		#var highest_aiko_age = 0.0
		#for aiko in curr_aikos:
			#highest_aiko_age = maxf(highest_aiko_age, aiko.calc_age())
		#aiko_ga.evaluate_generation()
		#aiko_ga.curr_generation += 1

#endregion


#region utils
func random_pos(_min: Vector2, _max: Vector2):
	var random = RandomNumberGenerator.new()
	var pos = Vector2(
		random.randf_range(_min.x, _max.x), 
		random.randf_range(_min.y, _max.y)) - global_position
	return pos

func random_angle():
	var random = RandomNumberGenerator.new()
	return random.randf_range(-PI, PI)
#endregion
