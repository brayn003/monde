@tool
class_name CreatureBody
extends RigidBody2D

var _size = 10.0

# traits
var _thrust = Vector2(200, 0)
var _torque = 200.0

# vision
var _vision_range = 1000.0
var _vision_angle = (TAU) / 3  # 180 deg
var _ray_casts: Array[RayCast2D] = []
var _no_of_ray_casts_per_zone = 6
var _no_of_vision_zones = 3
var _no_of_ray_casts = _no_of_ray_casts_per_zone * _no_of_vision_zones

var is_moving = false
var curr_actions = []

func _ready() -> void:
	_ready_collision_objects()
	_ready_raycasts()
	_ready_clickable_area()

func _ready_collision_objects() -> void:
	var collision_body = $CollisionBody
	collision_body.shape.radius = _size / 2
	
func _ready_clickable_area() -> void:
	var clickable_area = Area2D.new()
	var clickable_area_collision = CollisionShape2D.new()
	clickable_area.name = "Clickable"
	clickable_area_collision.name = "CollisionClickable"
	clickable_area_collision.shape = CircleShape2D.new()
	clickable_area_collision.shape.radius = (_size / 2) + 5.0
	clickable_area.add_child(clickable_area_collision)
	clickable_area.input_event.connect(_on_clickable_input_event)
	add_child(clickable_area)

func _ready_raycasts() -> void:
	# Create ray casters and append them in an array
	var cast_angle = - (_vision_angle / 2)
	var cast_arc = _vision_angle / _no_of_ray_casts
	for i in _no_of_ray_casts:
		var caster = RayCast2D.new()
		var cast_point = Vector2(_vision_range, 0).rotated(cast_angle)
		caster.enabled = false
		caster.target_position = cast_point
		caster.collide_with_areas = false
		caster.collide_with_bodies = true
		add_child(caster)
		_ray_casts.push_front(caster)
		cast_angle += cast_arc

func _integrate_forces(state):
	if not curr_actions.is_empty():
		_action_move(state)
		_action_turn(state)

func _action_move(state: PhysicsDirectBodyState2D) -> void:
	#var wants_to_move_up = actions[ACTION.MOVE_UP] > 0.5 if is_auto else Input.is_action_pressed("ui_up")
	#var wants_to_move_down = actions[ACTION.MOVE_DOWN] > 0.5 if is_auto else Input.is_action_pressed("ui_down")
	var final_force = Vector2.ZERO
	var move_intensity = remap(curr_actions[Piki.ACTION.MOVE], 0, 1, -1, 1)
	if move_intensity < -0.2 or move_intensity > 0.2:
		is_moving = true
		if move_intensity > 0:
			final_force = _thrust.rotated(rotation) * move_intensity
		elif move_intensity < 0:
			final_force = -1 * _thrust.rotated(rotation) * 0.2 * move_intensity
	
	state.apply_force(final_force)

func _action_turn(state: PhysicsDirectBodyState2D) -> void:
	var turn_intensity = remap(curr_actions[Piki.ACTION.TURN], 0, 1, -1, 1) 
	if turn_intensity < -0.2 or turn_intensity > 0.2:
		state.apply_torque(turn_intensity * _torque)

#func action_rest(delta: float) -> void:
	#var wants_to_rest = curr_actions[Piki.ACTION.REST] > 0.7
	#if wants_to_rest and not is_moving:
		#if hp < max_hp:
			#hp += 1.0 * delta
			#consume_energy(1.0 * delta)

#func sense_physical_state() -> Array[float]:
	#var senses: Array[float] = []
	#senses.append(linear_velocity.length())
	#senses.append(remap(linear_velocity.angle(), -TAU, TAU, -1, 1))
	#senses.append(remap(rotation, -TAU, TAU, -1, 1))
	#return senses

func _sense_items_in_sight() -> Array[float]:
	var senses: Array[float] = []
	# get the distance to the nearest obstacles
	for zone_index in _no_of_vision_zones:
		var relative_distance = 1.0
		var relative_angle = 0.0
		var item_type = 0.0
		
		for index in _no_of_ray_casts_per_zone:
			var caster_index = (zone_index * _no_of_ray_casts_per_zone) + index
			var caster = _ray_casts[caster_index]
			caster.force_raycast_update()
			if caster.is_colliding():
				var collision_item = caster.get_collider()
				var collision = caster.get_collision_point()
				
				var distance = global_position.distance_to(collision)
				var angle = get_angle_to(collision)
				var _relative_distance = remap(distance, 0, _vision_range, 0, 1)
				var _relative_angle = remap(angle, -PI, PI, -1, 1)
				
				var _item_type = 0.0
				if collision_item is ConsumableBody:
					_item_type = 1.0
				elif collision_item is PlantBody:
					_item_type = 0.3
				elif collision_item is AikoBody:
					_item_type = -0.9
				elif collision_item is PikiBody:
					_item_type = 0.8
				elif collision_item is WorldBounds:
					_item_type = 0.1

					
				if _relative_distance < relative_distance:
					relative_distance = _relative_distance 
					relative_angle = _relative_angle
					item_type = _item_type
					
		senses.append(relative_distance)
		senses.append(relative_angle)
		senses.append(item_type)
		
		relative_distance = 1.0
		relative_angle = 1.0
		item_type = 0.0
	
	return senses

func _on_clickable_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var parent = get_parent()
		parent.clicked.emit(parent)
