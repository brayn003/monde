class_name World
extends Node2D

signal select_entity(creature: Creature)
signal clock_tick(world: World)

const PIKI_SCENE: Resource = preload("res://game/Creature/creatures/Piki/Piki.tscn")
const AIKO_SCENE: Resource = preload("res://game/Creature/creatures/Aiko/Aiko.tscn")

var _scene_map = {
	Constants.Family.PIKI: PIKI_SCENE,
	Constants.Family.AIKO: AIKO_SCENE,
}
var _ga = {
	Constants.Family.PIKI: GeneticAlgorithm.new(9, 2, "piki"),
	Constants.Family.AIKO: GeneticAlgorithm.new(9, 2, "aiko"),
}

var _spawning_family := Constants.Family.NONE
var _spawning_placeholder: CreatureBodyRender

# time
var curr_time: int = 0
#var _time_since_last_gen: int = 0
#var _generation_step: int = 60

@onready var _gui: Gui = $"../Gui"
@onready var _camera: Camera = $"../Camera"
@onready var _terrain: Terrain = $Terrain

func _ready() -> void:
	#_create_planet()
	#add_child(piki_ga)
	#add_child(aiko_ga)
	#_spawn_initial_pikis()
	#_spawn_initial_aikos()
	_ready_clock()
	_ready_gui()

func _ready_clock() -> void:
	var clock: Timer
	clock = Timer.new()
	add_child(clock)
	clock.wait_time = 1.0
	clock.timeout.connect(_on_clock_timeout)
	clock.start()

func _ready_gui() -> void:
	_gui.toggled_spawn.connect(_on_gui_toggled_spawn)
	clock_tick.connect(_gui._on_world_clock_tick)
	select_entity.connect(_gui._on_world_select_entity)

func _input(event: InputEvent) -> void:
	_input_spawn_click(event)
	_input_reset_selected_entity(event)

func _input_spawn_click(event: InputEvent) -> void:
	if is_instance_valid(_spawning_placeholder):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_spawn_initial_creature(_spawning_family, get_global_mouse_position())

func _input_reset_selected_entity(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		select_entity.emit(null)
		_camera.select_entity(null)

func _process(_delta):
	_process_spawn_placeholder()

func _process_spawn_placeholder() -> void:
	if is_instance_valid(_spawning_placeholder):
		var mouse_positoion = get_local_mouse_position()
		_spawning_placeholder.position = mouse_positoion

func _on_creature_death(creature: Creature) -> void:
	var creature_ga = _ga[creature.family]
	creature_ga.free_genome(creature._genome)
	var curr_creatures = get_tree().get_nodes_in_group("creatures")
	curr_creatures.erase(creature)
	creature.queue_free()
	if _gui.selected_entity == creature:
		select_entity.emit(curr_creatures[-1] if curr_creatures.size() > 0 else null)
	if _camera.selected_entity == creature:
		_camera.select_entity(curr_creatures[-1] if curr_creatures.size() > 0 else null)

func _on_creature_spawn(parent_creature: Creature) -> void:
	var creature_ga = _ga[parent_creature.family]
	var genome = creature_ga.create_upgraded_genome(parent_creature._genome)
	_create_creature(
		parent_creature.family,
		genome, 
		parent_creature.body.position, 
		random_angle(), 
		parent_creature.generation)
	
func _on_creature_clicked(creature: Creature) -> void:
	if _spawning_family == Constants.Family.NONE:
		select_entity.emit(creature)
		#_gui.select_entity(creature)
		_camera.select_entity(creature)

func _on_clock_timeout() -> void:
	curr_time += 1
	clock_tick.emit(self)
	
	_terrain.generate_fruits()
	
	#if curr_time % _generation_step == 0:
		#_time_since_last_gen = 0
		
		#var highest_piki_age = 0.0
		#for piki in curr_pikis:
			#highest_piki_age = maxf(highest_piki_age, piki._age)
		#piki_ga.evaluate_generation()
		# there might be an issue here
		#piki_ga.curr_generation += 1
		
		#var highest_aiko_age = 0.0
		#for aiko in curr_aikos:
			#highest_aiko_age = maxf(highest_aiko_age, aiko.calc_age())
		#aiko_ga.evaluate_generation()
		#aiko_ga.curr_generation += 1

func _on_gui_toggled_spawn(family: Constants.Family) -> void:
	_spawning_family = family
	
	if is_instance_valid(_spawning_placeholder):
		_spawning_placeholder.queue_free()
		_spawning_placeholder = null
	
	match _spawning_family:
		Constants.Family.PIKI:
			_spawning_placeholder = PikiBodyRender.new()
		Constants.Family.AIKO:
			_spawning_placeholder = AikoBodyRender.new()
	
	if _spawning_placeholder:
		add_child(_spawning_placeholder)

func _create_creature(
	family: Constants.Family,
	genome: Genome, 
	input_position: Vector2 = Vector2(0, 0), 
	_input_rotation: float = random_angle(),
	_prev_gen: int = 0
	) -> void:
	var creature: Creature = _scene_map[family].instantiate()
	creature.generation = _prev_gen + 1
	creature.add_genome(genome)
	creature.death.connect(_on_creature_death)
	creature.spawn.connect(_on_creature_spawn)
	creature.clicked.connect(_on_creature_clicked)
	add_child(creature)
	creature.body.position = input_position
	creature.body.rotation = _input_rotation

func _spawn_initial_creature(
	family: Constants.Family,
	spawn_position: Vector2) -> void:
	var creature_ga = _ga[Constants.Family.PIKI]
	var genome = creature_ga.create_base_genome()
	_create_creature(family, genome, spawn_position, random_angle())

func random_pos(_min: Vector2, _max: Vector2):
	var random = RandomNumberGenerator.new()
	var pos = Vector2(
		random.randf_range(_min.x, _max.x), 
		random.randf_range(_min.y, _max.y)) - global_position
	return pos

func random_angle():
	var random = RandomNumberGenerator.new()
	return random.randf_range(-PI, PI)
