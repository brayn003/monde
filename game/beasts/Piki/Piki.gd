class_name Piki
extends Organism

enum ACTION {
	MOVE,
	TURN,
}

# ratios
var max_health_ratio = 1
var max_energy_ratio = 1
var initial_energy_ratio = 1

# state 
var max_hp = max_health_ratio * Constants.PIKI_MAX_HP
var max_energy = max_energy_ratio * Constants.PIKI_MAX_ENERGY
var hp = max_hp
var energy = initial_energy_ratio * Constants.PIKI_INITIAL_ENERGY

# sense
var food_eaten = 0
var no_of_spawns = 0
var spawn_wait_time = 20.0
var eat_wait_time = 0.0

# metabolism
var _metabolic_cost = 0.2
var _movement_cost = 0.8

# misc
var is_auto = true
var age = 0.0

@onready var body: PikiBody = $Body
@onready var clickable: Area2D = $Body/Clickable

func _process(delta) -> void:
	if is_born and not is_dead:
		age += delta
		
		if hp <= 0 or age > 60:
			die()
		
		if energy < 0:
			body.movement_ratio = 0.5
		else:
			body.movement_ratio = 1
		
		_process_living_cost(delta)
		_process_cooldowns(delta)

func _process_living_cost(delta: float) -> void:
	var cost = _metabolic_cost * delta
	if body.is_moving:
		cost += _movement_cost * delta
	_deduct_energy(cost)

func _process_cooldowns(delta: float) -> void:
	if spawn_wait_time > 0:
		spawn_wait_time -= delta
	if eat_wait_time > 0:
		eat_wait_time -= delta

func _act(actions: Array[float]) -> void:
	body.curr_actions = actions
	_spawn_offspring(actions)

func _sense() -> Array[float]:
	var senses: Array[float] = []
	#senses.append_array([hp, energy])
	#senses.append_array(body.sense_physical_state())
	senses.append_array(body.sense_items_in_sight())
	return senses

func _get_fitness() -> float:
	var _fitness = 0.0
	_fitness += pow(no_of_spawns, 3) * 100
	_fitness += pow(food_eaten, 2) * 100
	_fitness += age
	return _fitness

func _on_clickable_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		clicked.emit(self)

func _spawn_offspring(_actions: Array[float]) -> void:
	var population = get_tree().get_node_count_in_group("pikis")
	if population <= Constants.MAX_PIKIS and energy > 20 and spawn_wait_time <= 0:
		_deduct_energy(20)
		no_of_spawns += 1
		spawn.emit(self)
		spawn_wait_time = 5

func _deduct_hp(damage: float) -> void:
	if damage > hp:
		hp = 0
	else:
		hp -= damage

func _deduct_energy(cost: float) -> void:
	var diff = energy - cost
	if diff < 0:
		energy = 0
		_deduct_hp(absf(diff))
	else:
		energy -= cost

func _on_body_body_entered(collision_body: Node) -> void:
	if collision_body is ConsumableBody:
		var fruit: Consumable = collision_body.parent
		if energy <= max_energy - fruit.ENERGY_VALUE and eat_wait_time <= 0:
			food_eaten += 1
			energy += fruit.ENERGY_VALUE
			fruit.queue_free()
			eat_wait_time = 1.0
	
