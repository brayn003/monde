class_name WorldBounds
extends StaticBody2D

@onready var TopBound = $Top
@onready var RightBound = $Right
@onready var BottomBound = $Bottom
@onready var LeftBound = $Left

func _ready() -> void:
	TopBound.position = Constants.WORLD_BOUND_TOP
	RightBound.position = Constants.WORLD_BOUND_RIGHT
	BottomBound.position = Constants.WORLD_BOUND_BOTTOM
	LeftBound.position = Constants.WORLD_BOUND_LEFT
