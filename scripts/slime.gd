class_name Slime
extends RigidBody2D

signal birth
signal death

enum ACTION {
	MOVE_UP,
	MOVE_DOWN,
	TURN_LEFT,
	TURN_RIGHT,
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
var ray_casters: Array[RayCast2D] = []
var num_casts = 16


# sense
var is_alive = false
var is_moving = false
var food_eaten = 0
var nearby_items = []

func _ready() -> void:
	
	# init sight
	var cast_angle = 0
	var cast_arc = vision_angle / num_casts
	for _caster in num_casts:
		var caster = RayCast2D.new()
		var cast_point = Vector2(0, -vision_range).rotated(cast_angle)
		caster.enabled = false
		caster.target_position = cast_point
		caster.collide_with_areas = true
		caster.collide_with_bodies = false
		add_child(caster)
		ray_casters.append(caster)
		cast_angle += cast_arc
		
		
	birth.emit()
	is_alive = true
	add_to_group("slimes")
		
	
	
func _process(delta):
	if not is_alive:
		return
	# death
	if hp <= 0:
		die()
	consume_energy(delta, 1)

func consume_energy(delta, energy_cost):
	if energy > 0:
		energy -= energy_cost * delta
	else:
		hp -= 1 * delta

func die():
	death.emit()

func _integrate_forces(state):
	if not is_alive or not actions:
		return
		
	if actions[ACTION.MOVE_UP] > 0.5:
		state.apply_force(thrust.rotated(rotation))
	elif actions[ACTION.MOVE_DOWN] > 0.5:
		state.apply_force(-thrust.rotated(rotation))
	else:
		state.apply_force(Vector2())
		
	var rotation_direction = 0
	if actions[ACTION.TURN_LEFT] > 0.5:
		rotation_direction += 1
	if actions[ACTION.TURN_RIGHT] > 0.5:
		rotation_direction -= 1
	state.apply_torque(rotation_direction * torque)
	
#func _integrate_forces(state):
	#if not is_alive or not actions:
		#return
		#
	#if Input.is_action_pressed("ui_up"):
		#state.apply_force(thrust.rotated(rotation))
	#elif Input.is_action_pressed("ui_down"):
		#state.apply_force(-thrust.rotated(rotation))
	#else:
		#state.apply_force(Vector2())
		#
	#var rotation_direction = 0
	#if Input.is_action_pressed("ui_left"):
		#rotation_direction -= 1
	#if Input.is_action_pressed("ui_right"):
		#rotation_direction += 1
	#state.apply_torque(rotation_direction * torque)

func sense():
	senses.clear()
	sense_active_state()
	sense_items_in_sight()
	
func sense_active_state() -> void:
	senses.append(remap(hp, 0, max_hp, 0, 1))
	senses.append(remap(energy, 0, max_energy, 0, 1))
	senses.append(linear_velocity.length())
	senses.append(remap(linear_velocity.angle(), -TAU, TAU, -1, 1))
	senses.append(angular_velocity)
	senses.append(remap(rotation, -TAU, TAU, -1, 1))
	
func sense_items_in_sight() -> void:
	var processed_senses = []
	# get the distance to the nearest obstacles
	var num_zones = 4
	for zone_index in range(4):
		var relative_distance = 1.0
		var relative_angle = 1.0
		var item_type = 0.0
		
		for index in range(num_casts / num_zones):
			var caster = ray_casters[zone_index + index]
			caster.force_raycast_update()
			if caster.is_colliding():
				var collision_item = caster.get_collider()
				var collision = caster.get_collision_point()
				
				var distance = global_position.distance_to(collision)
				var angle = global_position.angle_to(collision)
				var _relative_distance = remap(distance, 0, vision_range, 0, 1)
				var _relative_angle = remap(angle, -PI, PI, -1, 1)
				
				var _item_type = 0.0
				if collision_item is Food:
					item_type = 1.0
				elif collision_item is Slime:
					item_type = 0.5
					
				if relative_distance > _relative_distance:
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
	for i in food_eaten:
		fitness += pow(i + 1, 2)
	return fitness
