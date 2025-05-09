class_name Creature
extends Node

enum ACTION {
	MOVE,
	TURN,
}

# signals
signal death(organism: Creature)

# hp
var _max_hp = 10.0
var _hp = _max_hp

# energy
var _initial_energy = 20.0
var _max_energy = 100.0
var _energy = _initial_energy

# sense
var _food_count = 0
var _food_wait = 0.0

# metabolism
var _metabolic_cost = 0.2
var _movement_cost = 0.8

# neural network
var _genome: Genome
var _nn: NeuralNet

# clock
var _clock: Timer
var _clock_speed = 2

# life-cycle
var _born_on
var _died_on
var _is_dead = false
var _is_born = false
var _max_age = 60.0
var _age = 0.0

# public
var family = Constants.Family.BASE

@onready var body: CreatureBody = $Body

func _ready() -> void:
	add_to_group("creatures")
	_ready_body()
	_ready_clock()

func _ready_body() -> void:
	body.contact_monitor = true
	body.max_contacts_reported = 1
	body.body_entered.connect(_on_body_body_entered)

func _ready_clock() -> void:
	_clock = Timer.new()
	_clock.timeout.connect(_on_clock_timeout)
	add_child(_clock)
	_clock.wait_time = 1.0 / _clock_speed
	_is_born = true
	_born_on = Time.get_unix_time_from_system()
	_clock.start()

func _process(delta) -> void:
	if _is_born and not _is_dead:
		_process_hp(delta)
		_process_age(delta)
		_process_living_cost(delta)
		_process_cooldowns(delta)

func _process_hp(_delta: float) -> void:
	if _hp <= 0:
		_die()

func _process_age(delta: float) -> void:
	_age += delta

func _process_living_cost(delta: float) -> void:
	var cost = _metabolic_cost * delta
	if body.is_moving:
		cost += _movement_cost * delta
	_deduct_energy(cost)

func _process_cooldowns(delta: float) -> void:
	if _food_wait > 0:
		_food_wait -= delta

func _on_body_body_entered(collision_body: Node) -> void:
	if collision_body is ConsumableBody:
		var fruit: Consumable = collision_body.get_parent()
		if _energy <= _max_energy - fruit.ENERGY_VALUE and _food_wait <= 0:
			_food_count += 1
			_energy += fruit.ENERGY_VALUE
			fruit.queue_free()
			_food_wait = 1.0

func _on_clock_timeout() -> void:
	if _is_born and not _is_dead:
		# fitness
		_genome.fitness = get_fitness()
		# senses and actions
		var senses = _sense()
		var actions = _nn.update(senses)
		_act(actions)

func _act(actions: Array[float]) -> void:
	body.curr_actions = actions

func _sense() -> Array[float]:
	var senses: Array[float] = []
	senses.append_array(_sense_state())
	senses.append_array(body.sense_physical_state())
	senses.append_array(body._sense_items_in_sight())
	return senses

func _sense_state() -> Array[float]:
	var senses: Array[float] = []
	senses.append(remap(_hp, 0, _max_hp, 0, 1))
	senses.append(remap(_energy, 0, _max_energy, 0, 1))
	return senses

func get_fitness() -> float:
	var _fitness = 0.0
	_fitness += _food_count
	return _fitness

func _die() -> void:
	_is_dead = true
	_died_on = Time.get_unix_time_from_system()
	_clock.stop()
	_genome.fitness = get_fitness()
	death.emit(self)

func _deduct_hp(damage: float) -> void:
	if damage > _hp:
		_hp = 0
	else:
		_hp -= damage

func _deduct_energy(cost: float) -> void:
	var diff = _energy - cost
	if diff < 0:
		_energy = 0
		_deduct_hp(absf(diff))
	else:
		_energy -= cost

func add_genome(input_genome: Genome) -> void:
	_genome = input_genome
	_nn = NeuralNet.new(_genome._params, _genome.neurons, _genome.links)
