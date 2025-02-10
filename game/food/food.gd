class_name Food
extends Area2D

func _ready() -> void:
	add_to_group("food")

func _on_body_entered(body: Node2D) -> void:
	body.energy += 20
	body.food_eaten += 1
	queue_free()
