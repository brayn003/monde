class_name Species
extends RefCounted

"""Species are a means for the NEAT algorithm to group structurally similar networks
together. The GeneticAlgorithm class uses species to provide new genomes by either
calling elite_spawn(), mate_spawn() or asex_spawn() on a species.
This grouping is necessary to achieve 'fitness sharing', meaning that the fitness
of individual members contributes to the fitness of the entire species, which in
turn determines how many new members the species will spawn in the next generation.
"""

var _params: CreatureParams = null

# unique string consisting of the generation the species was founded in, and the
# genome that founded species
var species_id: String
# How many generations this species has existed for

var _members: Array[Genome] = []
var pool: Array[Genome] = []

var _age = 0
var _spawn_count = 0
var _best_ever_fitness = 0
var _curr_mutation_rate = Constants.MutationRate.NORMAL

var leader: Genome = null
var representative: Genome = null
var avg_fitness = 0
var avg_fitness_adjusted = 0
var obliterate = false

func _init(params: CreatureParams, id: String) -> void:
	_params = params
	species_id = id

func add_member(genome: Genome):
	_members.append(genome)
	genome.species_id = species_id

func update() -> void:
	# members
	_members.sort_custom(func (m1, m2): return m1.fitness > m2.fitness)
	var alive_members: Array[Genome] = []
	var dead_members: Array[Genome] = []
	for member in _members:
		if member.is_active:
			alive_members.append(member)
		else:
			dead_members.append(member)
	
	# pool
	var _pool = dead_members
	if _pool.size() > _params.selection_threshold:
		pool = _pool.slice(0, _params.selection_threshold)
	else:
		pool = _pool.slice(0, _pool.size())
	
	# leader
	leader = pool[0]
	if leader.fitness > _best_ever_fitness:
		_best_ever_fitness = leader.fitness
	
	# representative
	if _params.update_species_rep:
		representative = leader if _params.leader_is_rep else Utils.random_choice(pool)
		
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
	var num_gens_no_improvement = highest_gen - leader.generation
	if num_gens_no_improvement > _params.enough_gens_to_change_things:
		_curr_mutation_rate = Constants.MutationRate.HIGH
	else:
		_curr_mutation_rate = Constants.MutationRate.NORMAL
	
	# averages
	var fit_modif = _params.youth_bonus if _age < _params.old_age else _params.old_penalty
	avg_fitness = get_avg_fitness()
	avg_fitness_adjusted = avg_fitness * fit_modif

	# obliterate
	if alive_members.size() < 1 and num_gens_no_improvement > _params.allowed_gens_no_improvement:
		obliterate = true

	# print
	print("Species %s has %d members, %d alive, %d dead" % [species_id, _members.size(), alive_members.size(), dead_members.size()])
	var pool_fitness = pool.map(func (m: Genome): return m.fitness)
	print("Pool fitness: %s" % [pool_fitness])

	# trim members
	var trimmed_members: Array[Genome] = []
	trimmed_members.append_array(alive_members)
	trimmed_members.append_array(pool)
	trimmed_members.assign(Utils.arr_unique(trimmed_members) as Array[Genome])
	_members = trimmed_members


func get_avg_fitness() -> float:
	"""Returns the average fitness of all alive members in the species
	"""
	var total_fitness = 0
	for member in _members:
		total_fitness += member.fitness
	return (total_fitness / _members.size())

func elite_spawn(g_id: int) -> Genome:
	"""Returns a clone of the species leader without increasing spawn count
	"""
	return leader.clone(g_id)

func mate_spawn(g_id: int) -> Genome:
	"""Chooses to members from the pool and produces a baby via crossover. Baby
	then gets mutated and returned.
	"""
	var mom: Genome; var dad: Genome; var baby: Genome
	# if random mating, pick 2 random unique parent genomes for crossing over.
	if _params.random_mating:
		var found_mate = false
		while not found_mate:
			dad = Utils.random_choice(pool)
			mom = Utils.random_choice(pool)
			if dad != mom:
				found_mate = true
	# else just go through every member of the pool, possibly multiple times and
	# breed genomes sorted by their fitness. Genomes with fitness scores next to each
	# other are therefore picked as mates, the exception being the first and last one.
	else:
		var pool_index = _spawn_count % (pool.size() - 1)
		mom = pool[pool_index]
		# ensure that second parent is not out of pool bounds
		dad = pool[-1] if pool_index == 0 else pool[pool_index + 1]
	# now that the parents are determined, produce a baby and mutate it
	baby = dad.crossover(mom, g_id)
	baby.mutate(_curr_mutation_rate)
	baby.generation = max(dad.generation, mom.generation) + 1
	_spawn_count += 1
	return baby

func asex_spawn(g_id) -> Genome:
	"""Clones a member from the pool, mutates it, and returns it.
	"""
	var baby: Genome
	# As long as not every pool member as been spawned, pick next one from pool
	if _spawn_count < pool.size():
		baby = pool[_spawn_count].clone(g_id)
	# if more spawns than pool size, start again
	else:
		baby = pool[_spawn_count % pool.size()].clone(g_id)
	baby.mutate(_curr_mutation_rate)
	baby.generation = baby.generation + 1
	_spawn_count += 1
	return baby
