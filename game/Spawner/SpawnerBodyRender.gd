@tool
class_name SpawnerBodyRender
extends Node2D

var _icon: CreatureBodyRender = null

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	var body_radius = Constants.SPAWNER_BODY_SIZE / 2.0
	draw_circle(Vector2.ZERO, body_radius, "#333333", true)
	
func add_icon(family: Constants.Family) -> void:
	if is_instance_valid(_icon):
		_icon.queue_free()

	var _scale_ratio = 1.0
	var _creature_size = 1.0
	
	match family:
		Constants.Family.PIKI:
			_icon = PikiBodyRender.new()
			_creature_size = Constants.PIKI_SIZE
		Constants.Family.AIKO:
			_icon = AikoBodyRender.new()
			_creature_size = Constants.AIKO_SIZE
		Constants.Family.BASE:
			_icon = CreatureBodyRender.new()
			_creature_size = Constants.PIKI_SIZE
			
	_scale_ratio = (Constants.SPAWNER_BODY_SIZE - 30.0) / _creature_size
	
	if _icon:
		add_child(_icon)
		_icon.scale = Vector2.ONE * _scale_ratio
		_icon.rotation = TAU / 3
		_icon.position = Vector2(-1.5, -1.5).rotated(_icon.rotation)
