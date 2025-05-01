class_name SlimeBody
extends RigidBody2D

var thrust_ratio = 1.0
var torque_ratio = 1.0
var vision_range_ratio = 1.0
var vision_angle_ratio = 1.0

var movement_ratio = 1.0

# traits
var max_linear_velocity = 200
var max_angular_velocity = TAU
var thrust =  Constants.SLIME_THRUST * thrust_ratio * movement_ratio
var torque = Constants.SLIME_TORQUE * torque_ratio  * movement_ratio

# vision
var vision_range = Constants.SLIME_VISION_RANGE * vision_range_ratio
var vision_angle = Constants.SLIME_VISION_ANGLE * vision_angle_ratio
var ray_casts: Array[RayCast2D] = []
var no_of_ray_casts_per_zone = 24
var no_of_vision_zones = 1
var no_of_ray_casts = no_of_ray_casts_per_zone * no_of_vision_zones

var is_moving = false
var curr_actions = []

func _ready() -> void:
	#region Init sight
	# Create ray casters and append them in an array
	var cast_angle = - (vision_angle / 2)
	var cast_arc = vision_angle / no_of_ray_casts
	for i in no_of_ray_casts:
		var caster = RayCast2D.new()
		var cast_point = Vector2(vision_range, 0).rotated(cast_angle)
		caster.enabled = false
		caster.target_position = cast_point
		caster.collide_with_areas = false
		caster.collide_with_bodies = true
		add_child(caster)
		ray_casts.push_front(caster)
		cast_angle += cast_arc
	
	add_to_group("slimes")
	#endregion

#func _process(delta: float) -> void:
	#action_rest(delta)
	
func _integrate_forces(state):
	if not curr_actions.is_empty():
		action_move(state)
		action_turn(state)

func action_move(state: PhysicsDirectBodyState2D) -> void:
	#var wants_to_move_up = actions[ACTION.MOVE_UP] > 0.5 if is_auto else Input.is_action_pressed("ui_up")
	#var wants_to_move_down = actions[ACTION.MOVE_DOWN] > 0.5 if is_auto else Input.is_action_pressed("ui_down")
	
	var intensity_up = curr_actions[Slime.ACTION.MOVE_UP]
	var intensity_down = curr_actions[Slime.ACTION.MOVE_DOWN]
	
	
	if intensity_up or intensity_down :
		is_moving = true
		if intensity_up:
			state.apply_force(thrust.rotated(rotation) * intensity_up)
		if intensity_down:
			state.apply_force( thrust.rotated(rotation) * (-1) * 0.2 * intensity_down)
	else:
		state.apply_force(Vector2())
		
func action_turn(state: PhysicsDirectBodyState2D) -> void:
	var intensity_left = curr_actions[Slime.ACTION.TURN_LEFT]
	var intensity_right = curr_actions[Slime.ACTION.TURN_RIGHT]
	var rotation_direction = 0
	
	if intensity_right:
		rotation_direction += 1 * intensity_right
	if intensity_left:
		rotation_direction -= 1 * intensity_left
	if rotation_direction != 0:
		is_moving = true
	state.apply_torque(rotation_direction * torque)

#func action_rest(delta: float) -> void:
	#var wants_to_rest = curr_actions[Slime.ACTION.REST] > 0.7
	#if wants_to_rest and not is_moving:
		#if hp < max_hp:
			#hp += 1.0 * delta
			#consume_energy(1.0 * delta)
	
func sense_physical_state() -> Array[float]:
	var senses: Array[float] = []
	senses.append(linear_velocity.length())
	senses.append(remap(linear_velocity.angle(), -TAU, TAU, -1, 1))
	senses.append(remap(rotation, -TAU, TAU, -1, 1))
	return senses
	
func sense_items_in_sight() -> Array[float]:
	var senses: Array[float] = []
	# get the distance to the nearest obstacles
	for zone_index in no_of_vision_zones:
		var relative_distance = 1.0
		var relative_angle = 0.0
		var item_type = 0.0
		
		for index in no_of_ray_casts_per_zone:
			var caster_index = (zone_index * no_of_ray_casts_per_zone) + index
			var caster = ray_casts[caster_index]
			caster.force_raycast_update()
			if caster.is_colliding():
				var collision_item = caster.get_collider()
				var collision = caster.get_collision_point()
				
				var distance = global_position.distance_to(collision)
				var angle = get_angle_to(collision)
				var _relative_distance = remap(distance, 0, vision_range, 0, 1)
				var _relative_angle = remap(angle, -PI, PI, -1, 1)
				
				var _item_type = -0.1
				if collision_item is Consumable or collision_item is Plant:
					_item_type = 1.0
				elif collision_item is Slime:
					_item_type = 0.5

					
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
