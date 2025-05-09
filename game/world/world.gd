class_name World
extends Node2D

signal select_entity(creature: Creature)
signal clock_tick(world: World)

const SPAWNER_SCENE := preload("res://game/Spawner/Spawner.tscn")

var _ga = {
	Constants.Family.PIKI: GeneticAlgorithm.new(Constants.Family.PIKI, 8, 2),
	Constants.Family.AIKO: GeneticAlgorithm.new(Constants.Family.AIKO, 8, 2),
}

var _build_spawner_family := Constants.Family.NONE
var _build_spawner_placeholder: SpawnerBodyRender

var _selected_entity: Creature = null

var curr_time: int = 0

@onready var _gui: Gui = $"../Gui"
@onready var _camera: Camera = $"../Camera"
@onready var _terrain: Terrain = $Terrain
@onready var _selector: WorldSelector = $Selector

func _ready() -> void:
	_ready_clock()
	_ready_camera()
	_ready_gui()
	_ready_selector()

func _ready_clock() -> void:
	var clock: Timer
	clock = Timer.new()
	add_child(clock)
	clock.wait_time = 1.0
	clock.timeout.connect(_on_clock_timeout)
	clock.start()

func _ready_gui() -> void:
	_gui.clicked_build_spawner.connect(_on_gui_toggled_spawn)
	clock_tick.connect(_gui._on_world_clock_tick)
	select_entity.connect(_gui._on_world_select_entity)

func _ready_selector() -> void:
	_selector.clicked.connect(_on_selector_clicked)

func _ready_camera() -> void:
	select_entity.connect(_camera._on_world_select_entity)

func _input(event: InputEvent) -> void:
	_input_build_spawner(event)

func _input_build_spawner(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			_build_spawner(_build_spawner_family, get_global_mouse_position())

func _process(_delta) -> void:
	_process_spawn_placeholder()
	_process_selector()

func _process_spawn_placeholder() -> void:
	if is_instance_valid(_build_spawner_placeholder):
		var mouse_position = get_local_mouse_position()
		_build_spawner_placeholder.position = mouse_position

func _process_selector() -> void:
	_selector.position = get_global_mouse_position()

func _on_selector_clicked(creature: Creature) -> void:
	_selected_entity = creature
	select_entity.emit(creature)

func _on_clock_timeout() -> void:
	curr_time += 1
	clock_tick.emit(self)
	
	_terrain.generate_fruits()

func _on_gui_toggled_spawn(family: Constants.Family) -> void:
	_build_spawner_family = family
	
	if is_instance_valid(_build_spawner_placeholder):
		_build_spawner_placeholder.queue_free()
		_build_spawner_placeholder = null
	
	if family != Constants.Family.NONE:
		_build_spawner_placeholder = SpawnerBodyRender.new()
		_build_spawner_placeholder.add_icon(family)
	
	if _build_spawner_placeholder:
		add_child(_build_spawner_placeholder)

func _on_spawner_despawned(creature: Creature) -> void:
	if creature == _selected_entity:
		select_entity.emit(null)
	_selected_entity = null

func _build_spawner(family: Constants.Family, input_position: Vector2) -> void:
	if is_instance_valid(_build_spawner_placeholder):
		var spawner: Spawner = SPAWNER_SCENE.instantiate()
		spawner.despawned.connect(_on_spawner_despawned)
		add_child(spawner)
		spawner.add_family(family)
		spawner.add_ga(_ga[family])
		spawner.position = input_position
