class_name GeneticAlgorithm
extends RefCounted


"""This class is responsible for generating genomes, placing them into species and
evaluating them. It can be viewed as the main orchestrator of the evolution process,
by delegating the exact details of how each step is achieved to the other classes
within this directory.
"""


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



var curr_species: Dictionary = {}
var curr_genomes: Dictionary = {}


# how many species got purged, and how many new species were founded in the curr generation
var num_dead_species = 0
var num_new_species = 0

# the NeatGUI node is a child of ga, and manages the creation and destruction
# of other GUI nodes.
var gui

 #0 = show all, 1 = show leaders, 2 = show none. Can be changed using gui
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
	# set_name("ga")
	# load the specified Params file
	Params.load_config(custom_params_name)
	# save all specified parameters in the Params singleton
	Params.num_inputs = number_inputs
	Params.num_outputs = number_outputs
	Params.agent_body_path = body_path
	Params.use_gui = use_gui
	# add the gui node as child
	#if use_gui:
		#gui = load("res://NEAT_usability/gui/NeatGUI.gd").new()
		#add_child(gui)
	
func create_base_genome() -> Genome:
	"""This method creates an initial genome. For the first set of
	genomes, there is just a limited number of links created, and no hidden
	neurons. Every genome gets assigned to a species, new species are created
	if necessary. Returns an initial genome.
	"""
	#region Creating blank genome
	var made_bias = false
	# current neuron_id is stored in Innovations, and gets incremented there
	var initial_neuron_id: int
	var input_neurons = {}; var output_neurons = {}
	# generate all input neurons and a bias neuron
	var input_pos = Vector2(0, 0)
	var diff = 1.0 / Params.num_inputs
	for i in Params.num_inputs + 1:
		# calculate the position of the input or bias neuron (in the first layer)
		var new_pos = input_pos
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
		input_pos.y += diff
		
	# now generate all output neurons
	var initial_output_y = 0.5 - (Params.num_outputs * diff) / 2.0
	var output_pos = Vector2(1, initial_output_y)
	for i in Params.num_outputs:
		var new_pos = output_pos
		initial_neuron_id = Innovations.store_neuron(Params.NEURON_TYPE.output)
		var new_neuron = Neuron.new(initial_neuron_id,
									Params.NEURON_TYPE.output,
									new_pos,
									Params.default_curve,
									false)
		output_neurons[initial_neuron_id] = new_neuron
		output_pos.y += diff
		
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
	#endregion
	
	# try to find a species to which the new genome is similar. If no existing
	# species is compatible with the genome, a new species is made and returned
	var species = find_species(genome)
	species.add_member(genome)
	
	curr_genomes[genome.id] = genome
	
	return genome

func create_upgraded_genome(genome: Genome) -> Genome:
	"""Goes through every species, and tries to spawn their new members (=genomes)
	either through crossover or asexual reproduction, until the max population size
	is reached. The new genomes then generate an agent, which will handle the
	interactions between the entity that lives in the simulated world, and the
	neural network that is coded for by the genome.
	"""
	var species: Species = curr_species[genome.species_id]
	species.update()
	
	var baby_genome: Genome
	#if not spawned_elite:
		#baby = species.elite_spawn(curr_genome_id)
		#spawned_elite = true
	if species.pool.size() < 2 or Utils.random_f() < Params.prob_asex:
		baby_genome = species.asex_spawn(curr_genome_id)
	else:
		baby_genome = species.mate_spawn(curr_genome_id)
		
	var baby_species = species
	if baby_genome.get_compatibility_score(species.representative) > Params.species_boundary:
		var found_species = find_species(baby_genome)
		found_species.add_member(baby_genome)
		baby_species = found_species
	else:
		baby_species.add_member(baby_genome)
	
	curr_genome_id += 1
	
	curr_genomes[baby_genome.id] = baby_genome
	
	return baby_genome

func free_genome(genome: Genome) -> void:
	var species: Species = curr_species[genome.species_id]
	species.expire_member(genome)
	curr_genomes.erase(genome)

func evaluate_generation() -> void:
	"""Must get called once before making a new generation. Kills all agents, updates the
	fitness of every genome, and assigns genomes to a species (or creates new ones).
	"""
	evaluate_curr_species()
	if Params.print_new_generation:
		print_status()
	num_new_species = 0

func find_species(new_genome: Genome) -> Species:
	"""Tries to find a species to which the given genome is similar enough to be
	added as a member. If no compatible species is found, a new one is made. Returns
	the species (but the genome still needs to be added as a member).
	"""
	var found_species: Species
	# try to find an existing species to which the genome is close enough to be a member
	var comp_score = Params.species_boundary
	for species in curr_species.values():
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
	curr_species[new_species.species_id] = new_species
	num_new_species += 1
	return new_species

func evaluate_curr_species() -> void:
	"""Determines which species will get to reproduce in the next generation.
	Calls the Species.update() method, which determines the species fitness as a
	group and removes all its members to make way for a new generation. Then loops
	over all species and updates the amount of offspring they will spawn the next
	generation.
	"""
	num_dead_species = 0
	# find the fittest genome from the last gen. Start with a random genome to allow comparison
	curr_best = Utils.random_choice(curr_genomes.values())
	# sum the average fitnesses of every species, and sum the average unadjusted fitness
	#var total_adjusted_species_avg_fitness = 0
	var total_species_avg_fitness = 0.0
	# this array holds the updated species
	var updated_species = {}
	var _best_species: Species
	var curr_species_arr = curr_species.values() as Array[Species]
	for species in curr_species_arr:
		# check if the species gets to survive
		if species.alive_members.size() > 0:
			species.update()
			
			updated_species[species.species_id] = species
			var species_fitness = species.avg_fitness
			total_species_avg_fitness += species_fitness
				
			if not _best_species or species_fitness > _best_species.avg_fitness:
				_best_species = species
				
			#total_adjusted_species_avg_fitness += species.avg_fitness_adjusted 
			# update curr_best genome and possibly all_time_best genome
			if species.leader.fitness > curr_best.fitness:
				if all_time_best and species.leader.fitness > all_time_best.fitness:
					all_time_best = species.leader
				curr_best = species.leader
		# remove dead species
		else:
			num_dead_species += 1
			
	# update avg population fitness of the previous generation
	avg_population_fitness = total_species_avg_fitness / curr_species.size()
	# this should not normally happen. Consider different parameters and starting a new run
	# if updated_species.size() == 0 or total_adjusted_species_avg_fitness == 0:
		#push_error("mass extinction"); breakpoint
		
	best_species = _best_species
	curr_species = updated_species

func print_status() -> void:
	"""Prints some basic information about the current progress of evolution.
	"""
	var print_str = """\n Last generation performance:
	\n generation number: {gen_id} \n number new species: {new_s}
	\n number dead species: {dead_s} \n total number of species: {tot_s}
	\n avg. fitness: {avg_fit} \n best fitness: {best} \n """
	var print_vars = {"gen_id" : curr_generation, "new_s" : num_new_species,
					  "dead_s" : num_dead_species, "tot_s" : curr_species.values().size(),
					  "avg_fit" : avg_population_fitness, "best" : curr_best.fitness}
	print(print_str.format(print_vars))

#func next_generation() -> void:
	#"""Goes through every species, and tries to spawn their new members (=genomes)
	#either through crossover or asexual reproduction, until the max population size
	#is reached. The new genomes then generate an agent, which will handle the
	#interactions between the entity that lives in the simulated world, and the
	#neural network that is coded for by the genome.
	#"""
	#if not generation_evaluated:
		#push_error("evaluate_generation() must be called before making a new generation")
		#breakpoint
	#curr_agents.clear()
	## keep track of new species, increment generation counter
	#num_new_species = 0
	#curr_generation += 1
	## keep track of spawned genomes, to not exceed population size
	#var num_spawned = 0
	#for species in curr_species:
		## reduce num_to_spawn if it would exceed population size
		#if num_spawned == Params.population_size:
			#break
		#elif num_spawned + species.num_to_spawn > Params.population_size:
			#species.num_to_spawn = Params.population_size - num_spawned
		## Elitism: best member of each species gets copied w.o. mutation
		#var spawned_elite = false
		## spawn all the new members of a species
		#for spawn in species.num_to_spawn:
			#var baby: Genome
			## first clone the species leader for elitism
			#if not spawned_elite:
				#baby = species.elite_spawn(curr_genome_id)
				#spawned_elite = true
			## if less than 2 members in spec., crossover cannot be performed
			## there is also prob_asex, which might result in an asex baby
			#elif species.pool.size() < 2 or Utils.random_f() < Params.prob_asex:
				#baby = species.asex_spawn(curr_genome_id)
			## produce a crossed-over genome
			#else:
				#baby = species.mate_spawn(curr_genome_id)
			## check if baby should speciate away from it's current species
			#var baby_species = species
			#if baby.get_compatibility_score(species.representative) > Params.species_boundary:
				## if the baby is too different, find an existing species to change
				## into. If no compatible species is found, a new one is made and returned
				#var found_species = find_species(baby)
				#found_species.add_member(baby)
				#baby_species = found_species
			#else:
				## If the baby is still within the species of it's parents, add it as member
				#baby_species.add_member(baby)
			#curr_genome_id += 1
			#num_spawned += 1
			## lastly generate an agent for the baby and append it to curr_agents
			#curr_agents.append(Agent.new(baby, baby_species))
	#
	### if all the current species di'dn't provide enough offspring, get some more
	##if Params.population_size - num_spawned > 0:
		##new_genomes += make_hybrids(Params.population_size - num_spawned)
	## let ui know that it should update the species list
	#generation_evaluated = false


#func make_hybrids(mm_nn, dad_nn) -> Array:
	#"""Go through every species num_to_spawn times, pick it's leader, and mate it
	#with a species leader from another species.
	#"""
	#var hybrids = []
	#var species_index = 0
	## ignore newly added species
	#if curr_species[species_index].age != 0:
		#var mom = curr_species[species_index].leader
		#var dad = curr_species[species_index + 1].leader
		#var baby = mom.crossover(dad, curr_genome_id)
		#curr_genome_id += 1
		## determine which species the new hybrid belongs to
		#var mom_score =  baby.get_compatibility_score(mom)
		#var dad_score =  baby.get_compatibility_score(dad)
		## find or make a new species if the baby matches none of the parents
		#var baby_species: Species
		#if mom_score > Params.species_boundary and dad_score > Params.species_boundary:
			#var found_species = find_species(baby)
			#found_species.add_member(baby)
			#baby_species = found_species
		## baby has a score closer to mom than to dad
		#elif mom_score < dad_score:
			#baby_species = curr_species[species_index]
			#baby_species.add_member(baby)
		## baby has a score closer to dad
		#else:
			#baby_species = curr_species[species_index + 1]
			#baby_species.add_member(baby)
		## make an agent for the baby, and append it to the curr_agents array
		#
		#
		#var baby_nn = NeuralNet.new(baby.neurons, baby.links)
		#curr_nns.append(baby_nn)
		#curr_genomes[baby_nn] = baby_genome
		#curr_species[baby_nn] = baby_species
		#
		#curr_agents.append(Agent.new(baby, baby_species))
		#hybrids.append(baby)
		## go to next species
		#species_index += 1 
		## if we went through every species, but still have spawns, go again
		#if species_index == curr_species.size() - 2:
			#species_index = 0
	#return hybrids
