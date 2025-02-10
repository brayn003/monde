class_name Slime
extends RigidBody2D

signal birth
signal death
signal spawns

enum ACTION {
	MOVE_UP,
	MOVE_DOWN,
	TURN_LEFT,
	TURN_RIGHT,
	REST,
}

var senses: Array = []
var actions: Array = []

# ratios
var max_health_ratio = 1
var max_energy_ratio = 1
var thrust_ratio = 1
var torque_ratio = 1
var vision_range_ratio = 1
var vision_angle_ratio = 1
var clock_speed_ratio = 1

# state 
var max_hp = max_health_ratio * Constants.SLIME_MAX_HP
var max_energy = max_health_ratio * Constants.SLIME_MAX_HP
var hp = max_hp
var energy = max_energy

# ratios - derived
var movement_penalty_ratio = 0.5 if energy <= 0 else 1.0

# traits
var max_linear_velocity = 200
var max_angular_velocity = TAU
var thrust =  Constants.SLIME_THRUST * thrust_ratio * movement_penalty_ratio
var torque = Constants.SLIME_TORQUE * torque_ratio  * movement_penalty_ratio

# clock
var clock_speed = Constants.SLIME_CLOCK_SPEED * clock_speed_ratio

# vision
var vision_range = Constants.SLIME_VISION_RANGE * vision_range_ratio
var vision_angle = Constants.SLIME_VISION_ANGLE * vision_angle_ratio
var ray_casts: Array[RayCast2D] = []
var no_of_ray_casts_per_zone = 8
var no_of_vision_zones = 5
var no_of_ray_casts = no_of_ray_casts_per_zone * no_of_vision_zones

# sense
var is_alive = false
var is_moving = false
var food_eaten = 0
var nearby_items = []

# misc
var is_auto = true


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
		caster.collide_with_areas = true
		caster.collide_with_bodies = false
		add_child(caster)
		ray_casts.push_front(caster)
		cast_angle += cast_arc
	
	birth.emit()
	is_alive = true
	add_to_group("slimes")
	#endregion
	
func _process(delta):
	if not is_alive or actions.is_empty():
		return
		
	consume_energy(delta)
	action_rest(delta)
	
	if hp <= 0:
		die()
	
	
func _integrate_forces(state):
	if not is_alive or actions.is_empty():
		return
	
	action_move(state)
	action_turn(state)
	
	
#func _integrate_forces(state):
	#if not is_alive or not actions:
		#return
		#
	#if Input.is_action_pressed("ui_up"):
		#state.apply_force(thrust.rotated(rotation))
	#elif Input.is_action_pressed("ui_down"):
		#state.apply_force(-(thrust * 0.2).rotated(rotation))
	#else:
		#state.apply_force(Vector2())
		#
	#var rotation_direction = 0
	#if Input.is_action_pressed("ui_left"):
		#rotation_direction -= 1
	#if Input.is_action_pressed("ui_right"):
		#rotation_direction += 1
	#state.apply_torque(rotation_direction * torque)
	
func deduct_hp(damage: float) -> void:
	if damage > hp:
		hp = 0
	else:
		hp -= damage
	
func consume_energy(delta: float) -> void:
	var energy_cost = 1.0 * delta # metabolic rate
	if is_moving:
		energy_cost += 1.0 * delta
	
	var diff = energy - energy_cost
	if diff < 0:
		energy = 0
		deduct_hp(absf(diff))
	else:
		energy -= energy_cost

func die():
	death.emit()
	
func action_move(state: PhysicsDirectBodyState2D) -> void:
	#var wants_to_move_up = actions[ACTION.MOVE_UP] > 0.5 if is_auto else Input.is_action_pressed("ui_up")
	#var wants_to_move_down = actions[ACTION.MOVE_DOWN] > 0.5 if is_auto else Input.is_action_pressed("ui_down")
	
	var intensity_up = actions[ACTION.MOVE_UP]
	var intensity_down = actions[ACTION.MOVE_DOWN]
	
	
	if intensity_up or intensity_down :
		is_moving = true
		if intensity_up:
			state.apply_force(thrust.rotated(rotation) * intensity_up)
		if intensity_down:
			state.apply_force( thrust.rotated(rotation) * (-1) * 0.2 * intensity_down)
	else:
		state.apply_force(Vector2())
		
func action_turn(state: PhysicsDirectBodyState2D) -> void:
	var intensity_left = actions[ACTION.TURN_LEFT]
	var intensity_right = actions[ACTION.TURN_RIGHT]
	var rotation_direction = 0
	
	if intensity_right:
		rotation_direction += 1 * intensity_right
	if intensity_left:
		rotation_direction -= 1 * intensity_left
	if rotation_direction != 0:
		is_moving = true
	state.apply_torque(rotation_direction * torque)

func action_rest(delta: float) -> void:
	var wants_to_rest = actions[ACTION.REST] > 0.7
	if wants_to_rest and not is_moving:
		if hp < max_hp:
			hp += 1.0 * delta
			consume_energy(1.0 * delta)

func sense():
	senses.clear()
	sense_active_state()
	sense_items_in_sight()
	
func sense_active_state() -> void:
	senses.append(remap(hp, 0, max_hp, 0, 1))
	senses.append(remap(energy, 0, max_energy, 0, 1))
	senses.append(food_eaten)
	senses.append(linear_velocity.length())
	senses.append(remap(linear_velocity.angle(), -TAU, TAU, -1, 1))
	senses.append(angular_velocity)
	senses.append(remap(rotation, -TAU, TAU, -1, 1))
	
func sense_items_in_sight() -> void:
	var processed_senses = []
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
				
				var _item_type = 0.0
				if collision_item is Food:
					item_type = 1.0
				elif collision_item is Slime:
					item_type = 0.5
					
				if _relative_distance < relative_distance:
					relative_distance = _relative_distance 
					relative_angle = _relative_angle
					item_type = _item_type
					
		processed_senses.append(relative_distance)
		processed_senses.append(relative_angle)
		processed_senses.append(item_type)
		
		relative_distance = 1.0
		relative_angle = 1.0
		item_type = 0.0
	senses.append_array(processed_senses)

	
func get_fitness():
	var fitness = 0
	fitness += 1 * pow(food_eaten, 2)
	fitness += 1 * hp
	fitness += 1 * energy
	return fitness
