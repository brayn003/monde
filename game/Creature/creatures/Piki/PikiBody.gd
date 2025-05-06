@tool
class_name PikiBody
extends CreatureBody

func _init() -> void:
	_size = Constants.PIKI_SIZE
	_thrust = Constants.PIKI_THRUST
	_torque = Constants.PIKI_TORQUE
	_vision_angle = Constants.PIKI_VISION_ANGLE
	_vision_range = Constants.PIKI_VISION_RANGE

func _ready_collision_objects() -> void:
	var collision_head: CollisionShape2D = $CollisionHead
	var collision_body: CollisionShape2D = $CollisionBody
	var collision_tail: CollisionShape2D = $CollisionTail
	
	var head_radius = (0.5 * _size) / 2
	var body_radius = (0.3 * _size) / 2
	var tail_radius = (0.2 * _size) / 2
	
	collision_head.shape.radius = head_radius
	collision_body.shape.radius = body_radius
	collision_tail.shape.radius = tail_radius
	
	collision_head.position = Vector2.ZERO
	collision_body.position = Vector2(-(head_radius + body_radius), 0)
	collision_tail.position = Vector2(-(head_radius + (2 * body_radius) + tail_radius), 0)
	
