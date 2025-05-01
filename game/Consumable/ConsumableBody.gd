class_name ConsumableBody
extends RigidBody2D

@onready var parent = get_parent() as Consumable
@onready var render = $Render
@onready var collision = $Collision

func _ready() -> void:
	var radius = parent.radius
	render.radius = radius
	render.queue_redraw()
	collision.shape.radius = radius
