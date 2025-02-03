class_name GeneticAlgorithm
extends Node


"""This class is responsible for generating genomes, placing them into species and
evaluating them. It can be viewed as the main orchestrator of the evolution process,
by delegating the exact details of how each step is achieved to the other classes
within this directory.
"""

signal made_new_gen

# curr_genome_id gets incremented for every new genome
var curr_genome_id = 0
# the current generation, starting with 1
var curr_generation = 1
# the average fitness of every currently alive genome
var avg_population_fitness = 0
# the all-time best genome
var all_time_best: Genome
# the best genome from the last generation
var curr_best: Genome
# the species with the best average fitness from the last generation
var best_species: Species
# array holding all agents, gets updated to only hold alive agents every timestep
var curr_agents: Array[Agent] = []
# an array containing species objects. Every species holds an array of members.
var curr_species = []
# how many species got purged, and how many new species were founded in the curr generation
var num_dead_species = 0
var num_new_species = 0

# the NeatGUI node is a child of ga, and manages the creation and destruction
# of other GUI nodes.
var gui

# True after evaluate_generation() is called, set to false when next_generation() is called
var generation_evaluated = false

# 0 = show all, 1 = show leaders, 2 = show none. Can be changed using gui
var curr_visibility = Params.default_visibility


func _init(number_inputs: int,
		   number_outputs: int,
		   body_path: String,
		   use_gui = false,
		   custom_params_name = "Default") -> void:
	"""Sets the undefined members of the Params Singleton according to the options
	in the constructor. Body path refers to the filepath for the agents body.
	Loads Params configuration if custom_Params_name is given. Creates the first
	set of genomes and agents, and creates a GUI if use_gui is true.
	"""
	# set the name of the node that contains GeneticAlgorithm Object
	set_name("ga")
	# load the specified Params file
	Params.load_config(custom_params_name)
	# save all specified parameters in the Params singleton
	Params.num_inputs = number_inputs
	Params.num_outputs = number_outputs
	Params.agent_body_path = body_path
	Params.use_gui = use_gui
	# add the gui node as child
	if use_gui:
		gui = load("res://NEAT_usability/gui/NeatGUI.gd").new()
		add_child(gui)


func create_initial_agent() -> Agent:
	"""This method creates an initial genome. For the first set of
	genomes, there is just a limited number of links created, and no hidden
	neurons. Every genome gets assigned to a species, new species are created
	if necessary. Returns an initial genome.
	"""
	var made_bias = false
	# current neuron_id is stored in Innovations, and gets incremented there
	var initial_neuron_id: int
	var input_neurons = {}; var output_neurons = {}
	# generate all input neurons and a bias neuron
	for i in Params.num_inputs + 1:
		# calculate the position of the input or bias neuron (in the first layer)
		var new_pos = Vector2(0, float(i)/Params.num_inputs)
		# the first neuron should be the bias neuron
		var neuron_type = Params.NEURON_TYPE.input
		if not made_bias:
			neuron_type = Params.NEURON_TYPE.bias
			made_bias = true
		# register neuron in Innovations, make the new neuron
		initial_neuron_id = Innovations.store_neuron(neuron_type)
		var new_neuron = Neuron.new(initial_neuron_id,
									neuron_type,
									new_pos,
									Params.default_curve,
									false)
		input_neurons[initial_neuron_id] = new_neuron
	# now generate all output neurons
	for i in Params.num_outputs:
		var new_pos = Vector2(1, float(i)/Params.num_outputs)
		initial_neuron_id = Innovations.store_neuron(Params.NEURON_TYPE.output)
		var new_neuron = Neuron.new(initial_neuron_id,
									Params.NEURON_TYPE.output,
									new_pos,
									Params.default_curve,
									false)
		output_neurons[initial_neuron_id] = new_neuron
	# merge input and output neurons into a single dict.
	var neurons = Utils.merge_dicts(input_neurons, output_neurons)
	
	var links = {}
	# count how many links are added
	var links_added = 0
	while links_added < Params.num_initial_links:
		# pick some random neuron id's from both input and output
		var from_neuron_id = Utils.random_choice(input_neurons.keys())
		var to_neuron_id = Utils.random_choice(output_neurons.keys())
		# don't add a link that connects from a bias neuron in the first gen
		if neurons[from_neuron_id].neuron_type != Params.NEURON_TYPE.bias:
			# Innovations returns either an existing or new id
			var innov_id = Innovations.check_new_link(from_neuron_id, to_neuron_id)
			# prevent adding duplicates
			if not links.has(innov_id):
				var new_link = Link.new(innov_id,
										Utils.gauss(Params.w_range),
										false,
										from_neuron_id,
										to_neuron_id)
				# add the new link to the genome
				links[innov_id] = new_link
				links_added += 1
	# increase genome counter, create a new genome
	curr_genome_id += 1
	var genome = Genome.new(curr_genome_id, neurons, links)
	# try to find a species to which the new genome is similar. If no existing
	# species is compatible with the genome, a new species is made and returned
	var found_species = find_species(genome)
	found_species.add_member(genome)
	# create a new neural network with the specified gene
	var agent = Agent.new(genome)
	curr_agents.append(agent)
	return agent

func evaluate_generation() -> void:
	"""Must get called once before making a new generation. Kills all agents, updates the
	fitness of every genome, and assigns genomes to a species (or creates new ones).
	"""
	for agent in curr_agents:
		if not agent.is_dead:
			agent.body.die()
	# Get updated list of species that survived into the next generation, and update
	# their spawn amounts based on fitness. Also updates the curr_best, all_time_best
	# and best_species based on the fitness of the last generation.
	curr_species = update_curr_species()
	# print some info about the last generation
	if Params.print_new_generation:
		print_status()
	generation_evaluated = true


func next_generation() -> Array[Agent]:
	"""Goes through every species, and tries to spawn their new members (=genomes)
	either through crossover or asexual reproduction, until the max population size
	is reached. The new genomes then generate an agent, which will handle the
	interactions between the entity that lives in the simulated world, and the
	neural network that is coded for by the genome.
	"""
	if not generation_evaluated:
		push_error("evaluate_generation() must be called before making a new generation")
		breakpoint
	curr_agents.clear()
	# keep track of new species, increment generation counter
	num_new_species = 0
	curr_generation += 1
	# keep track of spawned genomes, to not exceed population size
	var num_spawned = 0
	for species in curr_species:
		# reduce num_to_spawn if it would exceed population size
		if num_spawned == Params.population_size:
			break
		elif num_spawned + species.num_to_spawn > Params.population_size:
			species.num_to_spawn = Params.population_size - num_spawned
		# Elitism: best member of each species gets copied w.o. mutation
		var spawned_elite = false
		# spawn all the new members of a species
		for spawn in species.num_to_spawn:
			var baby: Genome
			# first clone the species leader for elitism
			if not spawned_elite:
				baby = species.elite_spawn(curr_genome_id)
				spawned_elite = true
			# if less than 2 members in spec., crossover cannot be performed
			# there is also prob_asex, which might result in an asex baby
			elif species.pool.size() < 2 or Utils.random_f() < Params.prob_asex:
				baby = species.asex_spawn(curr_genome_id)
			# produce a crossed-over genome
			else:
				baby = species.mate_spawn(curr_genome_id)
			# check if baby should speciate away from it's current species
			if baby.get_compatibility_score(species.representative) > Params.species_boundary:
				# if the baby is too different, find an existing species to change
				# into. If no compatible species is found, a new one is made and returned
				var found_species = find_species(baby)
				found_species.add_member(baby)
			else:
				# If the baby is still within the species of it's parents, add it as member
				species.add_member(baby)
			curr_genome_id += 1
			num_spawned += 1
			# lastly generate an agent for the baby and append it to curr_agents
			curr_agents.append(Agent.new(baby))
	
	## if all the current species di'dn't provide enough offspring, get some more
	#if Params.population_size - num_spawned > 0:
		#new_genomes += make_hybrids(Params.population_size - num_spawned)
	# let ui know that it should update the species list
	emit_signal("made_new_gen")
	generation_evaluated = false
	return curr_agents


func find_species(new_genome: Genome) -> Species:
	"""Tries to find a species to which the given genome is similar enough to be
	added as a member. If no compatible species is found, a new one is made. Returns
	the species (but the genome still needs to be added as a member).
	"""
	var found_species: Species
	# try to find an existing species to which the genome is close enough to be a member
	var comp_score = Params.species_boundary
	for species in curr_species:
		if new_genome.get_compatibility_score(species.representative) < comp_score:
			comp_score = new_genome.get_compatibility_score(species.representative)
			found_species = species
	# new genome matches no current species -> make a new one
	if typeof(found_species) == TYPE_NIL:
		found_species = make_new_species(new_genome)
	# return the species, whether it is new or not
	return found_species


func make_new_species(founding_member: Genome) -> Species:
	"""Generates a new species with a unique id, assigns the founding member as
	representative, and adds the new species to curr_species and returns it.
	"""
	var new_species_id = str(curr_generation) + "_" + str(founding_member.id)
	var new_species = Species.new(new_species_id)
	new_species.representative = founding_member
	curr_species.append(new_species)
	num_new_species += 1
	return new_species


func update_curr_species() -> Array:
	"""Determines which species will get to reproduce in the next generation.
	Calls the Species.update() method, which determines the species fitness as a
	group and removes all its members to make way for a new generation. Then loops
	over all species and updates the amount of offspring they will spawn the next
	generation.
	"""
	num_dead_species = 0
	# find the fittest genome from the last gen. Start with a random genome to allow comparison
	var curr_genomes = curr_agents.map(func (agent): return agent.genome)
	curr_best = Utils.random_choice(curr_genomes)
	# sum the average fitnesses of every species, and sum the average unadjusted fitness
	var total_adjusted_species_avg_fitness = 0
	var total_species_avg_fitness = 0
	# this array holds the updated species
	var updated_species = []
	for species in curr_species:
		# first update the species, this will check if the species gets to survive
		# into the next generation, update the species leader, calculate the average fitness
		# and calculate how many spawns the species gets to have in the next generation
		species.update()
		# check if the species gets to survive
		if not species.obliterate:
			updated_species.append(species)
			# collect the average fitness, and the adjusted average fitness
			total_species_avg_fitness += species.avg_fitness
			total_adjusted_species_avg_fitness += species.avg_fitness_adjusted 
			# update curr_best genome and possibly all_time_best genome
			if species.leader.fitness > curr_best.fitness:
				if all_time_best and species.leader.fitness > all_time_best.fitness:
					all_time_best = species.leader
				curr_best = species.leader
		# remove dead species
		else:
			num_dead_species += 1
			species.purge()
	# update avg population fitness of the previous generation
	avg_population_fitness = total_species_avg_fitness / curr_species.size()
	# this should not normally happen. Consider different parameters and starting a new run
	if updated_species.size() == 0 or total_adjusted_species_avg_fitness == 0:
		push_error("mass extinction"); breakpoint
	# loop through the species again to calculate their spawn amounts based on their
	# fitness relative to the total_adjusted_species_avg_fitness
	for species in updated_species:
		species.calculate_offspring_amount(total_adjusted_species_avg_fitness)
	# order the updated species by fitness, select the current best species, return
	updated_species.sort_custom(sort_by_spec_fitness)
	best_species = updated_species.front()
	return updated_species


func make_hybrids(num_to_spawn: int) -> Array:
	"""Go through every species num_to_spawn times, pick it's leader, and mate it
	with a species leader from another species.
	"""
	var hybrids = []
	var species_index = 0
	while not hybrids.size() == num_to_spawn:
		# ignore newly added species
		if curr_species[species_index].age != 0:
			var mom = curr_species[species_index].leader
			var dad = curr_species[species_index + 1].leader
			var baby = mom.crossover(dad, curr_genome_id)
			curr_genome_id += 1
			# determine which species the new hybrid belongs to
			var mom_score =  baby.get_compatibility_score(mom)
			var dad_score =  baby.get_compatibility_score(dad)
			# find or make a new species if the baby matches none of the parents
			if mom_score > Params.species_boundary and dad_score > Params.species_boundary:
				var found_species = find_species(baby)
				found_species.add_member(baby)
			# baby has a score closer to mom than to dad
			elif mom_score < dad_score:
				curr_species[species_index].add_member(baby)
			# baby has a score closer to dad
			else:
				curr_species[species_index + 1].add_member(baby)
			# make an agent for the baby, and append it to the curr_agents array
			curr_agents.append(Agent.new(baby))
			hybrids.append(baby)
		# go to next species
		species_index += 1 
		# if we went through every species, but still have spawns, go again
		if species_index == curr_species.size() - 2:
			species_index = 0
	return hybrids


func sort_by_spec_fitness(species1: Species, species2: Species) -> bool:
	"""Used for sort_custom(). Sorts species in descending order.
	"""
	return species1.avg_fitness > species2.avg_fitness



func print_status() -> void:
	"""Prints some basic information about the current progress of evolution.
	"""
	var print_str = """\n Last generation performance:
	\n generation number: {gen_id} \n number new species: {new_s}
	\n number dead species: {dead_s} \n total number of species: {tot_s}
	\n avg. fitness: {avg_fit} \n best fitness: {best} \n """
	var print_vars = {"gen_id" : curr_generation, "new_s" : num_new_species,
					  "dead_s" : num_dead_species, "tot_s" : curr_species.size(),
					  "avg_fit" : avg_population_fitness, "best" : curr_best.fitness}
	print(print_str.format(print_vars))
