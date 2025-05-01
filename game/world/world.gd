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

const slime_scene: Resource = preload("res://game/Slime/Slime.tscn")
const plant_scene: Resource = preload("res://game/Plant/Plant.tscn")
const planet_scene: Resource = preload("res://game/Planets/DryTerran/DryTerran.tscn")

const MAX_SLIME = 200
const MAX_PLANTS = 20

signal clock_tick(world: World)
signal gen_tick(world: World)

@onready var SLIME_SPAWN_MIN = -4 * get_viewport_rect().size
@onready var SLIME_SPAWN_MAX = 4 * get_viewport_rect().size
@onready var PLANT_SPAWN_MIN = -4 * get_viewport_rect().size
@onready var PLANT_SPAWN_MAX = 4 * get_viewport_rect().size

var clock: Timer
var curr_clock_time: int = 0
var time_since_last_gen: int = 0
# every generation_step a new generation is made. this gets increased over time.
var generation_step: int = 60

# fitness treshold is 100 secs
var fitness_threshold = 100

var curr_slimes = []

@onready var ga: GeneticAlgorithm = GeneticAlgorithm.new(6, 4, "res://game/Slime/Slime.tscn")
@onready var gui: Gui = $Gui
@onready var camera: Camera = $Camera
@onready var terrain: Terrain = $Terrain

func _ready() -> void:
	#_create_planet()
	add_child(ga)
	_spawn_initial_slimes()
	_spawn_plants()
	_start_clock()
	

func _create_planet() -> void:
	var planet: DryTerran = planet_scene.instantiate()
	add_child(planet)
	planet.set_seed(2219401622)
	planet.set_pixels(200)
	planet.position = Vector2.ZERO
	planet.set_dither(true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		gui.focus_on_organism(null)
		camera.focus_on_organism(null)
	
#region slimes

func _on_slime_death(slime: Slime) -> void:
	ga.free_genome(slime.genome)
	curr_slimes.erase(slime)
	slime.queue_free()
	if gui.focused_organism == slime:
		gui.focus_on_organism(curr_slimes[0] if curr_slimes.size() > 0 else null)
	if camera.focused_organism == slime:
		camera.focus_on_organism(curr_slimes[0] if curr_slimes.size() > 0 else null)

func _on_slime_spawn(parent_slime: Slime) -> void:
	if curr_slimes.size() >= MAX_SLIME:
		return
	var genome = ga.create_upgraded_genome(parent_slime.genome)
	create_slime(genome, parent_slime.body.position, random_angle(), parent_slime.generation)
	
func _on_slime_clicked(slime: Slime) -> void:
	gui.focus_on_organism(slime)
	camera.focus_on_organism(slime)

func create_slime(
	genome: Genome, 
	pos: Vector2 = Vector2(0, 0), 
	_rotation: float = 0,
	_prev_gen: int = 0
	) -> void:
	var slime: Slime = slime_scene.instantiate()
	slime.generation = _prev_gen + 1
	slime.add_genome(genome)
	slime.death.connect(_on_slime_death)
	slime.spawn.connect(_on_slime_spawn)
	slime.clicked.connect(_on_slime_clicked)
	add_child(slime)
	slime.body.position = pos
	slime.body.rotation = _rotation
	curr_slimes.append(slime)

func _spawn_initial_slimes() -> void:
	for i in MAX_SLIME:
		var genome = ga.create_base_genome()
		create_slime(genome, random_pos(SLIME_SPAWN_MIN, SLIME_SPAWN_MAX), random_angle())

#endregion

#region clock

func _start_clock():
	clock_tick.emit(self)
	clock = Timer.new()
	add_child(clock)
	clock.wait_time = 1.0
	clock.timeout.connect(_on_clock_time_step)
	clock.start()

func _on_clock_time_step() -> void:
	curr_clock_time += 1
	clock_tick.emit(self)
	if curr_clock_time % generation_step == 0:
		gen_tick.emit(self)
		time_since_last_gen = 0
		var highest_slime_age = 0.0
		for slime in curr_slimes:
			highest_slime_age = maxf(highest_slime_age, slime.calc_age())
		print("The oldest slime is living for " + str(highest_slime_age))
		print("=====Generation Step=====")
		ga.evaluate_generation()
		print("=========================")
		ga.curr_generation += 1

#endregion

#func reset_food() -> void:
	#var _food_items = get_tree().get_nodes_in_group("food")
	##for food in _food_items:
		##food.position = random_pos(FOOD_SPAWN_MIN, FOOD_SPAWN_MAX)
		#
	#var missing_count = MAX_FOOD - _food_items.size()
	#print(missing_count, " new food items were added to the existing ", _food_items.size())
	#for i in missing_count:
		#var food = food_scene.instantiate() as Area2D
		#food.position = random_pos(FOOD_SPAWN_MIN, FOOD_SPAWN_MAX)
		#add_child(food)
		
func _on_spawn(child: Node, from: Node) -> void:
	add_child(child)
	var origin = from.body.position
	child.body.position = random_pos(origin + Vector2(-20, -20), origin + Vector2(20, 20))
	child.body.rotation = random_angle()

func _spawn_plants() -> void:
	for i in MAX_PLANTS:
		var plant: Plant = plant_scene.instantiate()
		plant.spawn.connect(_on_spawn)
		add_child(plant)
		plant.body.position = random_pos(PLANT_SPAWN_MIN, PLANT_SPAWN_MAX)


#region utils
func random_pos(_min: Vector2, _max: Vector2):
	var random = RandomNumberGenerator.new()
	var pos = Vector2(
		random.randf_range(_min.x, _max.x), 
		random.randf_range(_min.y, _max.y)) - global_position
	var terrain_coords = terrain.local_to_map(pos)
	if terrain.get_cell_source_id(terrain_coords) == -1:
		return pos
	return random_pos(_min, _max)

func random_angle():
	var random = RandomNumberGenerator.new()
	return random.randf_range(-PI, PI)
#endregion
