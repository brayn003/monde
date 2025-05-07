@tool
class_name Spawner
extends Node2D

const PIKI_SCENE: Resource = preload("res://game/Creature/creatures/Piki/Piki.tscn")
const AIKO_SCENE: Resource = preload("res://game/Creature/creatures/Aiko/Aiko.tscn")

var _scene_map = {
	Constants.Family.PIKI: PIKI_SCENE,
	Constants.Family.AIKO: AIKO_SCENE,
}

var _ga : GeneticAlgorithm = null
var _family := Constants.Family.NONE
var _spawn_wait_time = 1.0

@onready var body := $Body
@onready var area := $Body/Area
@onready var _body_render := $Body/Render



func _ready() -> void:
	_ready_collision_areas()

func _ready_clock() -> void:
	var clock: Timer
	clock = Timer.new()
	add_child(clock)
	clock.wait_time = 1.0
	clock.timeout.connect(_on_clock_timeout)
	clock.start()

func _ready_collision_areas() -> void:
	var _body_collision := $Body/Collision
	var _area_collision := $Body/Area/Collision
	_body_collision.shape.radius = Constants.SPAWNER_BODY_SIZE / 2.0
	_area_collision.shape.radius = Constants.SPAWNER_AREA_SIZE / 2.0

func _on_clock_timeout() -> void:
	_spawn_creature()

func _spawn_creature() -> void:
	var creature: Creature = _scene_map[_family].instantiate()
	creature.add_genome(genome)
	creature.death.connect(_on_creature_death)
	creature.spawn.connect(_on_creature_spawn)
	creature.clicked.connect(_on_creature_clicked)
	add_child(creature)
	creature.body.position = input_position
	creature.body.rotation = _input_rotation

func add_family(family: Constants.Family) -> void:
	_family = family
	_body_render.add_icon(_family)
