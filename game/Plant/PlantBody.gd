class_name PlantBody
extends StaticBody2D

var _size_ratio = 1.0

var _size = Constants.PLANT_SIZE * _size_ratio
var radius = _size / 2.0

@onready var collision = $Collision

func _ready() -> void:
	collision.shape.radius = radius
	collision_layer = Constants.PLANT_COLLISION_LAYER
	set_collision_layer_value(1, false)
	set_collision_layer_value(Constants.PLANT_COLLISION_LAYER, true)
