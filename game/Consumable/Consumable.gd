class_name Consumable
extends Node


const ENERGY_VALUE = Constants.FRUIT_ENERGY

var radius = Constants.FRUIT_SIZE / 2.0

@onready var body: ConsumableBody = $Body

func _ready() -> void:
	add_to_group("consumables")
