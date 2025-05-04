class_name Plant
extends Node

const consumable_scene = preload("res://game/Consumable/Consumable.tscn")

signal spawn_fruit()

@onready var body = $Body

func _ready() -> void:
	add_to_group("plants")

func _on_spawn_fruit() -> void:
	var consumable: Consumable = consumable_scene.instantiate()
	get_parent().add_child(consumable)
	var prox_vect = Vector2(randf_range(body.radius + 10, 25), 0)
	consumable.body.position = body.position + prox_vect.rotated(randf_range(-TAU, TAU))
