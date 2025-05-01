class_name Slime
extends Organism

enum ACTION {
	MOVE_UP,
	MOVE_DOWN,
	TURN_LEFT,
	TURN_RIGHT,
}

# ratios
var max_health_ratio = 1
var max_energy_ratio = 1

# state 
var max_hp = max_health_ratio * Constants.SLIME_MAX_HP
var max_energy = max_energy_ratio * Constants.SLIME_MAX_ENERGY
var hp = max_hp
var energy = max_energy

# sense
var food_eaten = 0
var no_of_spawns = 0
var spawn_wait_time = 60

# misc
var is_auto = true
var age = 0.0

@onready var body: SlimeBody = $Body
@onready var clickable: Area2D = $Body/Clickable

func _process(delta):
	if is_born and not is_dead:
		age += delta
		
		if hp <= 0 or age > 300:
			die()
		
		if energy < 0:
			body.movement_ratio = 0.5
		else:
			body.movement_ratio = 1
		
		consume_energy(delta)
	
	if spawn_wait_time > 0:
		spawn_wait_time -= delta

func _act(actions: Array[float]) -> void:
	body.curr_actions = actions
	spawn_offspring(actions)

func _sense() -> Array[float]:
	var senses: Array[float] = []
	senses.append_array(body.sense_physical_state())
	senses.append_array(body.sense_items_in_sight())
	return senses

func _get_fitness() -> float:
	var _fitness = 0.0
	_fitness += 1 * pow(food_eaten, 2)
	_fitness += 1 * hp
	_fitness += 1 * energy
	return _fitness

func _on_clickable_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		clicked.emit(self)

func spawn_offspring(actions: Array[float]) -> void:
	if energy > 100 and spawn_wait_time <= 0:
		no_of_spawns += 1
		spawn.emit(self)
		spawn_wait_time = 30

func deduct_hp(damage: float) -> void:
	if damage > hp:
		hp = 0
	else:
		hp -= damage

func consume_energy(delta: float) -> void:
	var energy_cost = 1.0 * delta # metabolic rate
	if body.is_moving:
		energy_cost += 1.0 * delta
	
	var diff = energy - energy_cost
	if diff < 0:
		energy = 0
		deduct_hp(absf(diff))
	else:
		energy -= energy_cost

func _on_body_body_entered(body: Node) -> void:
	if body is ConsumableBody:
		food_eaten += 1
		energy += body.parent.consume()
	
