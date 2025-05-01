class_name Organism
extends Node

""" Agents may only be created by the GeneticAlgorithm class. Agents generate the
entity that interacts with the world. This is the agents body. The Agent is also
provided upon its creation a neural network that was coded for by the genome that
generated the agent.

The Agent provides a sort of interface for the GA class to handle all interactions
between the body, controlled by a neural network, and the environment it lives in.

The body must have a method called act(), that uses the outputs of the neural network.
Furthermore a method called sense() must be provided, that returns an array containing
the observations from the environment which are used as inputs to the nn. The third
method that the body must have is called get_fitness(), which returns a POSITIVE
real or integer number that represents how well the agent has acted in this generation.

Lastly, the agent must emit a 'death' signal if it dies.
"""

signal death(organism: Organism)
signal spawn(organism: Organism)
signal clicked(organism: Organism)

# nn related
var genome: Genome
var nn: NeuralNet

# clock
var clock_speed = Constants.SLIME_CLOCK_SPEED
var clock: Timer

# life-cycle
var born_on
var died_on
var is_dead = false
var is_born = false

# misc
var generation = 0
var fitness = 0

func _ready() -> void:
	#body = load(Params.agent_body_path).instantiate()
	#body.birth.connect(on_body_birth)
	#body.death.connect(on_body_death)
	
	clock = Timer.new()
	add_child(clock)
	clock.wait_time = 1.0 / clock_speed
	clock.timeout.connect(_on_clock_tick)
	
	is_born = true
	born_on = Time.get_unix_time_from_system()
	clock.start()

func _get_fitness() -> float:
	return 0.0
	
func _sense() -> Array[float]:
	return []
	
func _act(_actions: Array[float]):
	pass
	
func _on_clock_tick() -> void:
	if is_born and not is_dead:
		process_senses_and_actions()

func _on_genome_update_fitness() -> void:
	var _fitness = _get_fitness()
	genome.fitness = _fitness

func process_senses_and_actions() -> void:
	var senses = _sense()
	var actions = nn.update(senses)
	_act(actions)
	#pass

func add_genome(_genome: Genome) -> void:
	genome = _genome
	nn = NeuralNet.new(genome.neurons, genome.links)
	genome.update_fitness.connect(_on_genome_update_fitness)

func die() -> void:
	is_dead = true
	died_on = Time.get_unix_time_from_system()
	clock.stop()
	fitness = _get_fitness()
	death.emit(self)
	
func calc_age() -> float:
	var age = 0.0
	if is_dead:
		age = died_on - born_on
	else:
		age = Time.get_unix_time_from_system() - born_on
	return age
