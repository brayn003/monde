class_name Agent
extends RefCounted

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

# related to nn
var genome: Genome
var network: NeuralNet
var body: Node

# clock
var clock: Timer
var delta: float

# life-cycle
var born_on
var died_on
var is_dead = false
var is_born = false

# misc
var fitness = 0

func _init(_genome: Genome) -> void:
	genome = _genome
	network = NeuralNet.new(genome.neurons, genome.links)
	
	body = load(Params.agent_body_path).instantiate()
	body.birth.connect(on_body_birth)
	body.death.connect(on_body_death)
	
	delta = 1.0 / body.clock_speed
	clock = Timer.new()
	body.add_child(clock)
	clock.wait_time = delta
	clock.timeout.connect(_on_clock_tick)
	
func _on_clock_tick() -> void:
	if not is_born or is_dead:
		return
	body.sense()
	body.senses.append(get_age())
	var actions = network.update(body.senses)
	body.actions = actions
	
func get_age() -> float:
	var age = 0.0
	if is_dead:
		age = died_on - born_on
	else:
		age = Time.get_unix_time_from_system() - born_on
	return age

func on_body_birth() -> void:
	is_born = true
	born_on = Time.get_unix_time_from_system()
	clock.start()

func on_body_death() -> void:
	is_dead = true
	died_on = Time.get_unix_time_from_system()
	clock.stop()
	fitness = body.get_fitness()
	genome.fitness = fitness
	body.queue_free()
	
