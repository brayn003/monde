class_name Consumable
extends Node

var radius = 10.0
var energy = 20.0

@onready var body: ConsumableBody = $Body

func _ready() -> void:
	add_to_group("consumables")

func consume() -> float:
	queue_free()
	return energy
