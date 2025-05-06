class_name Terrain
extends Node2D

const plant_scene: Resource = preload("res://game/Plant/Plant.tscn")


var _fnl = FastNoiseLite.new()

var _cell_size = 32
var _top_bound = Constants.WORLD_BOUND_TOP.y / _cell_size
var _right_bound = Constants.WORLD_BOUND_RIGHT.x / _cell_size
var _bottom_bound = Constants.WORLD_BOUND_BOTTOM.y / _cell_size
var _left_bound = Constants.WORLD_BOUND_LEFT.x / _cell_size

var _fruits_per_tick = 10
var _initial_fruit_count = 1000

func _ready() -> void:
	_ready_plant_terrain()

func _ready_plant_terrain() -> void:
	randomize()
	_fnl.seed = randi()
	_fnl.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_fnl.frequency = 0.025
	for x in range(_left_bound, _right_bound - 1):
		for y in range(_top_bound, _bottom_bound - 1):
			var noise_val = _fnl.get_noise_2d(x, y)
			if noise_val > 0.38:
				var _cell_x = (x * _cell_size) + (_cell_size / 2.0)
				var _cell_y = (y * _cell_size) + (_cell_size / 2.0)
				_spawn_plant(Vector2(_cell_x, _cell_y))

func _spawn_plant(pos: Vector2) -> void:
	var plant: Plant = plant_scene.instantiate()
	add_child(plant)
	plant.body.position = pos

func generate_fruits() -> void:
	var fruit_count = get_tree().get_node_count_in_group("consumables")
	var plants = get_tree().get_nodes_in_group("plants")
	if fruit_count >= 0 and fruit_count < Constants.MAX_FRUITS:
		var spawning_plants: Array[Plant] = []
		var no_of_fruits = _fruits_per_tick if fruit_count > _initial_fruit_count else 10 * _fruits_per_tick
		for i in no_of_fruits:
			spawning_plants.append(plants.pick_random())
		for plant in spawning_plants:
			plant.spawn_fruit.emit()
