class_name Species
extends RefCounted

"""Species are a means for the NEAT algorithm to group structurally similar networks
together. The GeneticAlgorithm class uses species to provide new genomes by either
calling elite_spawn(), mate_spawn() or asex_spawn() on a species.
This grouping is necessary to achieve 'fitness sharing', meaning that the fitness
of individual members contributes to the fitness of the entire species, which in
turn determines how many new members the species will spawn in the next generation.
"""

var _params: FamilyParams = null

# unique string consisting of the generation the species was founded in, and the
# genome that founded species
var species_id: String
# How many generations this species has existed for

var _members: Array[Genome] = []
var _pool: Array[Genome] = []
var _leader: Genome = null
var _representative: Genome = null

var _age = 0
var _spawn_count = 0
var _best_ever_fitness = 0
var _curr_mutation_rate = Constants.MutationRate.NORMAL

var avg_fitness = 0
var avg_fitness_adjusted = 0
var obliterate = false

func _init(params: FamilyParams, id: String) -> void:
	_params = params
	species_id = id

func add_member(genome: Genome):
	_members.append(genome)
	genome.species_id = species_id

func update() -> void:
	# members
	_members.sort_custom(func (m1, m2): return m1.fitness > m2.fitness)
	
	# pool
	var pool = _members.filter(func (m: Genome): return !m.is_active)
	if pool.size() > _params.selection_threshold:
		_pool = pool.slice(0, _params.selection_threshold)
	else:
		_pool = pool.slice(0, pool.size())
	
	# leader
	_leader = _pool[0]
	if _leader.fitness > _best_ever_fitness:
		_best_ever_fitness = _leader.fitness
	
	# representative
	if _params.update_species_rep:
		_representative = _leader if _params.leader_is_rep else Utils.random_choice(_members)
		
	# age
	var lowest_gen: int
	var highest_gen: int
	for member in _members:
		if not lowest_gen or member.generation < lowest_gen:
			lowest_gen = member.generation
		if not highest_gen or member.generation > highest_gen:
			highest_gen = member.generation
	_age = highest_gen - lowest_gen
	
	# mutation
	var num_gens_no_improvement = highest_gen - _leader.generation
	if num_gens_no_improvement > _params.allowed_gens_no_improvement:
		obliterate = true
	elif num_gens_no_improvement > _params.enough_gens_to_change_things:
		_curr_mutation_rate = Constants.MutationRate.HIGH
	else:
		_curr_mutation_rate = Constants.MutationRate.NORMAL
	
	# averages
	var fit_modif = _params.youth_bonus if _age < _params.old_age else _params.old_penalty
	avg_fitness = get_avg_fitness()
	avg_fitness_adjusted = avg_fitness * fit_modif

func get_avg_fitness() -> float:
	"""Returns the average fitness of all members in the species
	"""
	var total_fitness = 0
	for member in _members:
		total_fitness += member.fitness
	return (total_fitness / _members.size())

func elite_spawn(g_id: int) -> Genome:
	"""Returns a clone of the species _leader without increasing spawn count
	"""
	return _leader.clone(g_id)

func mate_spawn(g_id: int) -> Genome:
	"""Chooses to members from the pool and produces a baby via crossover. Baby
	then gets mutated and returned.
	"""
	var mom: Genome; var dad: Genome; var baby: Genome
	# if random mating, pick 2 random unique parent genomes for crossing over.
	if _params.random_mating:
		var found_mate = false
		while not found_mate:
			dad = Utils.random_choice(_pool)
			mom = Utils.random_choice(_pool)
			if dad != mom:
				found_mate = true
	# else just go through every member of the pool, possibly multiple times and
	# breed genomes sorted by their fitness. Genomes with fitness scores next to each
	# other are therefore picked as mates, the exception being the first and last one.
	else:
		var pool_index = _spawn_count % (_pool.size() - 1)
		mom = _pool[pool_index]
		# ensure that second parent is not out of pool bounds
		dad = _pool[-1] if pool_index == 0 else _pool[pool_index + 1]
	# now that the parents are determined, produce a baby and mutate it
	baby = dad.crossover(mom, g_id)
	baby.mutate(_curr_mutation_rate)
	_spawn_count += 1
	return baby

func asex_spawn(g_id) -> Genome:
	"""Clones a member from the pool, mutates it, and returns it.
	"""
	var baby: Genome
	# As long as not every pool member as been spawned, pick next one from pool
	if _spawn_count < _pool.size():
		baby = _pool[_spawn_count].clone(g_id)
	# if more spawns than pool size, start again
	else:
		baby = _pool[_spawn_count % _pool.size()].clone(g_id)
	baby.mutate(_curr_mutation_rate)
	_spawn_count += 1
	return baby
