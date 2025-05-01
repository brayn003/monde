class_name Plant
extends Node

const consumable_scene = preload("res://game/Consumable/Consumable.tscn")

signal spawn(fruit: Consumable, from: Plant)

var _clock_speed_ratio = 1.0
var _clock_speed = Constants.PLANT_CLOCK_SPEED * _clock_speed_ratio

@onready var clock: Timer = $Clock
@onready var body: PlantBody = $Body

func _ready() -> void:
	_ready_clock()
	
func _ready_clock() -> void:
	clock.wait_time = 1.0 / _clock_speed
	clock.start()

func _spawn_fruit() -> void:
	var existing_fruits = get_tree().get_node_count_in_group("consumables")
	if existing_fruits < Constants.MAX_FOOD:
		var consumable: Consumable = consumable_scene.instantiate()
		spawn.emit(consumable, self)

func _on_clock_timeout() -> void:
	_spawn_fruit()
