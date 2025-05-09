class_name GeneticAlgorithm
extends RefCounted

var params = CreatureParams.new()

var _curr_genome_id = 0

var _total_species_avg_fitness = 0.0
var _total_adjusted_species_avg_fitness = 0.0
var _avg_population_fitness = 0.0

var _curr_best_species: Species
var _curr_best_genome: Genome
var _all_time_best_genome: Genome

var _curr_species: Array[Species] = []
var _curr_genomes: Array[Genome] = []

func _init(
family: Constants.Family, 
num_inputs: int,
num_outputs: int) -> void:
	params.family = family
	params.num_inputs = num_inputs
	params.num_outputs = num_outputs

func _create_base_genome() -> Genome:
	var made_bias = false
	# current neuron_id is stored in Innovations, and gets incremented there
	var initial_neuron_id: int
	var input_neurons = {}; var output_neurons = {}
	# generate all input neurons and a bias neuron
	var input_pos = Vector2(0, 0)
	var diff = 1.0 / params.num_inputs
	for i in params.num_inputs + 1:
		# calculate the position of the input or bias neuron (in the first layer)
		var new_pos = input_pos
		# the first neuron should be the bias neuron
		var neuron_type := Constants.NeuronType.INPUT
		if not made_bias:
			neuron_type = Constants.NeuronType.BIAS
			made_bias = true
		# register neuron in Innovations, make the new neuron
		initial_neuron_id = Innovations.store_neuron(neuron_type)
		var new_neuron = Neuron.new(
			initial_neuron_id,
			neuron_type,
			new_pos,
			params.default_curve,
			false)
		input_neurons[initial_neuron_id] = new_neuron
		input_pos.y += diff
		
	# now generate all output neurons
	var initial_output_y = 0.5 - (params.num_outputs * diff) / 2.0
	var output_pos = Vector2(1, initial_output_y)
	for i in params.num_outputs:
		var new_pos = output_pos
		initial_neuron_id = Innovations.store_neuron(Constants.NeuronType.OUTPUT)
		var new_neuron = Neuron.new(
			initial_neuron_id,
			Constants.NeuronType.OUTPUT,
			new_pos,
			params.default_curve,
			false)
		output_neurons[initial_neuron_id] = new_neuron
		output_pos.y += diff
		
	# merge input and output neurons into a single dict.
	var neurons = Utils.merge_dicts(input_neurons, output_neurons)
	
	var links = {}
	# count how many links are added
	var links_added = 0
	while links_added < params.num_initial_links:
		# pick some random neuron id's from both input and output
		var from_neuron_id = Utils.random_choice(input_neurons.keys())
		var to_neuron_id = Utils.random_choice(output_neurons.keys())
		# don't add a link that connects from a bias neuron in the first gen
		if neurons[from_neuron_id].neuron_type != Constants.NeuronType.BIAS:
			# Innovations returns either an existing or new id
			var innov_id = Innovations.check_new_link(from_neuron_id, to_neuron_id)
			# prevent adding duplicates
			if not links.has(innov_id):
				var new_link = Link.new(
					innov_id,
					Utils.gauss(params.w_range),
					false,
					from_neuron_id,
					to_neuron_id)
				links[innov_id] = new_link
				links_added += 1
	
	_curr_genome_id += 1
	var genome = Genome.new(params, _curr_genome_id, neurons, links, 1)
	
	var species = _find_species(genome)
	species.add_member(genome)

	_curr_genomes.append(genome)
	return genome

func _create_upgraded_genome() -> Genome:
	var species = Utils.random_choice(_curr_species)
	var baby_genome: Genome
	_curr_genome_id += 1
	#if not spawned_elite:
		#baby = species.elite_spawn(_curr_genome_id)
		#spawned_elite = true
	if species.pool.size() < 2 or Utils.random_f() < params.prob_asex:
		baby_genome = species.asex_spawn(_curr_genome_id)
	else:
		baby_genome = species.mate_spawn(_curr_genome_id)

	var baby_species = species
	if baby_genome.get_compatibility_score(species.representative) > params.species_boundary:
		var found_species = _find_species(baby_genome)
		found_species.add_member(baby_genome)
		baby_species = found_species
		_evaluate_species(found_species)
	else:
		baby_species.add_member(baby_genome)
	
	
	_curr_genomes.append(baby_genome)
	
	return baby_genome

func _evaluate_species(species: Species) -> void:
	var old_species_fitness = species.avg_fitness
	var old_adjusted_species_fitness = species.avg_fitness_adjusted
	
	species.update()

	var species_fitness = species.avg_fitness if not species.obliterate else 0
	var adjusted_species_fitness = species.avg_fitness_adjusted if not species.obliterate else 0
	
	_total_species_avg_fitness += (species_fitness - old_species_fitness)
	_total_adjusted_species_avg_fitness += (adjusted_species_fitness - old_adjusted_species_fitness)
	
	if species.obliterate:
		_curr_species.erase(species)
	
	_avg_population_fitness = _total_species_avg_fitness / _curr_species.size()

	if not species.obliterate:
		if not _curr_best_species or species_fitness > _curr_best_species.avg_fitness:
			_curr_best_species = species

		if not _curr_best_genome or species.leader.fitness > _curr_best_genome.fitness:
			if _all_time_best_genome and species.leader.fitness > _all_time_best_genome.fitness:
				_all_time_best_genome = species.leader
			_curr_best_genome = species.leader

	# if _total_adjusted_species_avg_fitness == 0:
	# 	push_error("mass extinction"); breakpoint

func _find_species(new_genome: Genome) -> Species:
	# # minimum compatibility score for two genomes to be considered in the same species
	# var species_boundary = 1.3
	# # coefficients for tweaking the compatibility score
	# var coeff_matched = 0.6
	# var coeff_disjoint = 1.2
	# var coeff_excess = 1.4

	var found_species: Species

	var comp_score = params.species_boundary
	for species in _curr_species:
		var _temp_comp_score = new_genome.get_compatibility_score(species.representative)
		if _temp_comp_score < comp_score:
			comp_score = _temp_comp_score
			found_species = species

	if typeof(found_species) == TYPE_NIL:
		found_species = _make_new_species(new_genome)

	return found_species

func _make_new_species(founding_member: Genome) -> Species:
	var new_species_id = str(founding_member.generation) + "_" + str(founding_member.id)
	var new_species = Species.new(params, new_species_id)
	new_species.representative = founding_member
	_curr_species.append(new_species)
	return new_species

func acquire_genome() -> Genome:
	# var max_base_count = Utils.math_combination(
	# 	(params.num_inputs +) * params.num_outputs, 
	# 	params.num_initial_links)
	var genome: Genome = null
	if _curr_genome_id <= params.num_base_genomes:
		genome = _create_base_genome()
	else:
		genome = _create_upgraded_genome()
	genome.is_active = true
	return genome

func release_genome(genome: Genome) -> void:
	genome.is_active = false
	var index = _curr_species.find_custom(func (s: Species): return s.species_id == genome.species_id)
	var species = _curr_species[index]
	_evaluate_species(species)
	_curr_genomes.erase(genome)

#func make_hybrids(mm_nn, dad_nn) -> Array:
	#"""Go through every species num_to_spawn times, pick it's leader, and mate it
	#with a species leader from another species.
	#"""
	#var hybrids = []
	#var species_index = 0
	## ignore newly added species
	#if _curr_species[species_index].age != 0:
		#var mom = _curr_species[species_index].leader
		#var dad = _curr_species[species_index + 1].leader
		#var baby = mom.crossover(dad, _curr_genome_id)
		#_curr_genome_id += 1
		## determine which species the new hybrid belongs to
		#var mom_score =  baby.get_compatibility_score(mom)
		#var dad_score =  baby.get_compatibility_score(dad)
		## find or make a new species if the baby matches none of the parents
		#var baby_species: Species
		#if mom_score > Params.species_boundary and dad_score > Params.species_boundary:
			#var found_species = _find_species(baby)
			#found_species.add_member(baby)
			#baby_species = found_species
		## baby has a score closer to mom than to dad
		#elif mom_score < dad_score:
			#baby_species = _curr_species[species_index]
			#baby_species.add_member(baby)
		## baby has a score closer to dad
		#else:
			#baby_species = _curr_species[species_index + 1]
			#baby_species.add_member(baby)
		## make an agent for the baby, and append it to the curr_agents array
		#
		#
		#var baby_nn = NeuralNet.new(baby.neurons, baby.links)
		#curr_nns.append(baby_nn)
		#curr_genomes[baby_nn] = baby_genome
		#_curr_species[baby_nn] = baby_species
		#
		#curr_agents.append(Agent.new(baby, baby_species))
		#hybrids.append(baby)
		## go to next species
		#species_index += 1 
		## if we went through every species, but still have spawns, go again
		#if species_index == _curr_species.size() - 2:
			#species_index = 0
	#return hybrids
