class_name Slime
extends CharacterBody2D

signal birth
signal death

# ratios
var max_health_ratio = 1
var max_energy_ratio = 1
var speed_ratio = 1
var angular_speed_ratio = 1
var vision_range_ratio = 1
var clock_speed_ratio = 1

# state 
var hp = max_health_ratio * Constants.SLIME_MAX_HP
var energy = max_energy_ratio * Constants.SLIME_MAX_ENERGY

# ratios - derived
var movement_penalty_ratio = 0.5 if energy <= 0 else 1.0

# traits
var speed =  Constants.SLIME_SPEED * speed_ratio * movement_penalty_ratio
var angular_speed = Constants.SLIME_ANGULAR_SPEED * angular_speed_ratio  * movement_penalty_ratio
var vision_range = Constants.SLIME_VISION_RANGE * vision_range_ratio

# clock
var clock_speed = Constants.SLIME_CLOCK_SPEED * clock_speed_ratio

# fitness
var food_eaten = 0

func _ready() -> void:
	add_to_group("slimes")
	$Sight/CollisionShape2D.shape.set_radius(vision_range)
	birth.emit()
#
#func _physics_process(delta):
	#if Input.is_action_pressed("ui_up"):
		#move_ahead(delta)
	#if Input.is_action_pressed("ui_left"):
		#turn_left(delta)
	#if Input.is_action_pressed("ui_right"):
		#turn_right(delta)
		
func _process(delta):
	consume_energy(delta, 1)
	if hp <= 0:
		die()

func consume_energy(delta, energy_cost):
	if energy > 0:
		energy -= energy_cost * delta
	else:
		hp -= 1 * delta

func die():
	death.emit()

func move_ahead(delta: float):
	var _velocity = Vector2.UP.rotated(rotation) * speed
	move_and_collide(_velocity * delta)

func move_back(delta: float):
	var _velocity = Vector2.LEFT.rotated(rotation) * speed
	move_and_collide(_velocity * delta)

#func move_left(delta: float):
	#var _velocity = Vector2.LEFT.rotated(rotation) * speed
	#move_and_collide(_velocity * delta)
#
#func move_right(delta: float):
	#var _velocity = Vector2.LEFT.rotated(rotation) * speed
	#move_and_collide(_velocity * delta)

func turn_left(delta: float):
	rotation -= angular_speed * delta

func turn_right(delta: float):
	rotation += angular_speed * delta
	
func see_nearby_items() -> Array:
	''' Returns an array of all the food bodies in range. 
	The items will be sorted from the nearest to the farthest
	'''
	var nearvy_items: Array = []
	var areas = ($Sight as Area2D).get_overlapping_areas()
	var bodies = ($Sight as Area2D).get_overlapping_bodies()
	var items = areas + bodies
	
	for item in items:
		var food_direction = position.direction_to(item.position)
		var straignt_direction = Vector2.RIGHT.rotated(rotation)
		if straignt_direction.dot(food_direction) > 0: # is in visible range
			nearvy_items.append({
				"item": item, 
				"pos": item.position - position
			})
	nearvy_items.sort_custom(func (a, b): return a.pos.length() < b.pos.length())
	return nearvy_items
	
func sense(_delta: float):
	var senses = []
	senses.append(hp)
	senses.append(energy)
	senses.append(speed)
	senses.append(angular_speed)
	
	var nearby_items = see_nearby_items()
	var distance_to_closest_food = 0
	var angle_to_closest_food = 0
	var no_of_food_items = 0
	var distance_to_closest_slime = 0
	var angle_to_closest_slime = 0
	var no_of_slimes = 0
	for nearby_item in nearby_items:
		if nearby_item.item is Food:
			if no_of_food_items == 0:
				distance_to_closest_food = nearby_item.pos.length()
				angle_to_closest_food = position.angle_to(nearby_item.pos)
			no_of_food_items += 1
		if nearby_item.item is Slime:
			if no_of_slimes == 0:
				distance_to_closest_slime = nearby_item.pos.length()
				angle_to_closest_slime = position.angle_to(nearby_item.pos)
			no_of_slimes += 1
	
	senses.append(distance_to_closest_food)
	senses.append(angle_to_closest_food)
	senses.append(no_of_food_items)
	senses.append(distance_to_closest_slime)
	senses.append(angle_to_closest_slime)
	senses.append(no_of_slimes)
	
	return senses

func act(delta: float, actions: Array):
	if actions[0] > 0.5:
		move_ahead(delta)
	if actions[1] > 0.5:
		move_back(delta)
	if actions[2] > 0.5:
		turn_left(delta)
	if actions[3] > 0.5:
		turn_right(delta)
	#if actions[4] > 0.5:
		#move_left(delta)
	#if actions[5] > 0.5:
		#move_right(delta)

func get_fitness():
	var fitness = 0
	fitness += food_eaten
	return fitness
