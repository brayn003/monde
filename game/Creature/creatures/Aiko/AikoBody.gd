@tool
class_name AikoBody
extends CreatureBody

func _init() -> void:
	_size = Constants.AIKO_SIZE
	_thrust = Constants.AIKO_THRUST
	_torque = Constants.AIKO_TORQUE
	_vision_angle = Constants.AIKO_VISION_ANGLE
	_vision_range = Constants.AIKO_VISION_RANGE

func _ready_collision_objects() -> void:
	var collision_body: CollisionShape2D = $CollisionBody
	var collision_tail: CollisionShape2D = $CollisionTail
	
	var body_radius = (0.7 * _size) / 2
	var tail_radius = (0.3 * _size) / 2
	
	collision_body.shape.radius = body_radius
	collision_tail.shape.radius = tail_radius
	
	collision_body.position = Vector2.ZERO
	collision_tail.position = Vector2(-(body_radius + tail_radius), 0)
	
