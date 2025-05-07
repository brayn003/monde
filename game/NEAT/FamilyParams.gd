class_name FamilyParams
extends RefCounted

var family := Constants.Family.NONE

# -------------------- GA SETTINGS -------------------- 

# ----- init method
# numbers of inputs and outputs that every neural net will have
var num_inputs: int
var num_outputs: int
# A path to the agent_body - the scene that represents the player, providing the
# sense(), act() and get_fitness() functions. This parameter is set by the user
# when a new GeneticAlgorithm node gets instanced.
var agent_body_path: String

# ----- change visibility of agent bodies
# If rendering costs too much performance, or clutter is to be avoided, agent.body
# nodes can be hidden using ga.update_visibility()
var visibility_options = ["Show all", "Show Leaders", "Show none"]
# the default visibility is an index to the visibility options. 0 = show all
# this setting can be changed during runtime via a species list popup
var default_visibility = 0

# ----- new_generation method
# Number of genomes agents existing at the same time (= one generation)
var population_size = 200
# turn on/off printing info about past generation, when making a new generation
var print_new_generation = true



# -------------------- NETWORK CONSTRAINTS -------------------- 

# ----- Generating a new network
# Because starting minimally is a very important factor in NEAT, this parameter
# determines how many input links get a connection to an output link, when creating
# the first set of genomes. My personal experience thus far has shown that this
# is one of the most crucial parameters for good performance. It is important to
# keep this number low, but definitely not too low. 40%-50% of the num of inputs
# is a good target to start with. It should also approach the number of inputs that
# are assumed to be important.
var num_initial_links = 2
# maximum amount of neurons, for performance reasons. can be set arbitrarily
var max_neuron_amt = 10

# ----- Chaining
# if prevent_chaining is true, only split links that connect to neurons having
# x values of either 0 or 1. This means that networks do not exceed a depth
# of one hidden layer until their amount of neurons exceeds this threshold.
var prevent_chaining = true
var chain_threshold = 3



# -------------------- GUI AND HIGHLIGHTER -------------------- 

# ----- general
# If set to true, ga will create a child node that will spawn all gui elements,
# and a highlighter will be created for every agent
var use_gui: bool

# ----- highlighter parameters
# enable the highlighter. Highlighter objects are still created if disabled, however
# their toggle is disabled, and they will never be drawn
var is_highlighter_enabled = true
# if the highlighter should be slightly offset, change this here
var highlighter_offset = Vector2(0, 0)
# the radius of the highlighter circle
var highlighter_radius = 100
# the color of the highlighter circle
var highlighter_color = Color.GREEN
# the thickness / width of the highlighter circle
var highlighter_width = 3



# -------------------- Crossover --------------------

# ----- mating
# Probability of skipping crossover generating new genomes
var prob_asex = 0.1
# probability of gene being inherited from the less fit parent. Lower number better.
# THIS IS NOT THE RATE OF SEX-REPRODUCTION. That would be 1 - prob_asex
var gene_swap_rate = 0.25
# when crossing over 2 individuals within the pool, pick random parents, or parents
# with similar fitness scores. keeping it false (=based on fitness) seems to yield
# the best results.
var random_mating = false



# -------------------- NEURON MUTATIONS --------------------

# ----- Adding neurons
# probabilities of adding a neuron in mutation func. There are two values for mutations,
# because if a species is stale for a while it's mutation probabilities are changed
# to the second value
var prob_add_neuron = [0.05, 0.15]
# default activation curve that neurons are initialized with. tanh default is 2. signm is 1
# the other defaults can be found in the activation function definitions in the
# neuralnet class.
var default_curve = 1.0

# ----- activation function mutations
# probabilities of changing the curve of the activation function. This mutation
# is applied on every link, meaning about this num reflects the percent of all
# neurons that will be changed.
var prob_activation_mut = [0.05, 0.05]
# activation gets increased/decreased by normal distribution. This is it's deviation.
var activation_shift_deviation = 0.3



# -------------------- LINK MUTATIONS --------------------

# ----- adding links
# probabilities of adding a link between random neurons in mutation func
var prob_add_link = [0.1, 0.3]
# probability of disabling a single link per mutation
var prob_disable_link = [0.1, 0.2]
# probabilities of adding a looping link (link that connects neuron to itself)
var prob_loop_link = [0.03, 0.1]
# probabilities of adding a direct link (link that directly connects input to output
# neurons). Useful when starting with few links, or when no good Innovations occur.
var prob_direct_link = [0, 0.2]
# disable mutations that produce feed back links
var no_feed_back = false
# number of attempts to find a neuron if there is no guarantee one will be found
var num_tries_find_link = 10

# ----- mutating weights
# probabilities of changing the weight of a link. This mutation is applied on every
# link, meaning about this num reflects the perc. of all links that will be changed
var prob_weight_mut = [0.3, 0.3]
# range in which new weights should be initialized
var w_range = 1.0
# completely changes weight. This can only happen if the the probability of a
# weight mutation is met. Therefore the prob is prob_weight_mut * prob_weight_replaced 
var prob_weight_replaced = [0.06, 0.15]
# weight gets increased/decreased by normal distribution. This is it's deviation.
var weight_shift_deviation = 0.4



# -------------------- SPECIATION --------------------

# ----- speciation and compatibility parameters
# minimum compatibility score for two genomes to be considered in the same species
var species_boundary = 1.3
# coefficients for tweaking the compatibility score
var coeff_matched = 0.6
var coeff_disjoint = 1.2
var coeff_excess = 1.4



# -------------------- SPECIES BEHAVIOR --------------------

# ----- species performance tracking
# if species start to become stale and don't improve for enough_gens_to_change_things 
# change MUTATION_STATE from normal to heightened. This will cause the second
# probability of the mutation options to be chosen when spawning new members.
var enough_gens_to_change_things = 4
# how many generations should be tolerated without improvement, after that, kill
# the species.
var allowed_gens_no_improvement = 8


# ----- fitness sharing parameters
# Params for rewarding/punishing species based on their age
var old_age = 7
var youth_bonus = 1.3
var old_penalty = 0.8

# ----- species update func
# should the species representative be updated, or stay the same for every gen
# If set to true, representative will determined by leader_is_rep,
# If set to false, representative will always be the founding genome
var update_species_rep = true
# If true, species leader is also it's representative. Else just a random member.
var leader_is_rep = false
# Determines what proportion of a species alive members should be considered when
# calling spawn. E.g. 10 members, spawn_cutoff: 0.5 --> pick among top 5 members.
var spawn_cutoff = 0.7
# Before a species reaches this num of members, the pool includes every member
# probably best to set this really high
var selection_threshold = 30



# -------------------- NEURAL_NET PARAMETERS -------------------- 

# ----- Network updates
# Should the network ensure that all inputs have been fully flushed through
# the network (=snapshot), or should it give an output after every neuron has
# been activated once (= active)
var is_runtype_active = true
# Change the activation function used in the neural network. Curr_activation func
# must be a string that exactly matches one of the activation function definitions,
# since it is directly used as a parameter for creating a funcref in the NeuralNet
# class. Currently implemented activation functions are: "sigm_activate",
# "tanh_activate", "gauss_activate"
var curr_activation_func = "sigm_activate"
# if set to true, input neurons pass their inputs through the defined activation
# function.
var activate_inputs = false

# ----- Network drawing
# colors of neuron types, when displaying a network. Map to NEURON_TYPE enum
var neuron_colors = [Color.TURQUOISE, Color.TEAL, Color.SEASHELL, Color.TOMATO]
# When coloring weights, weights >= num are colored red, weights <= are blue, 
# and everything inbetween uses this num as reference.
var weight_max_color = 4



# -------------------- INNOVATION PARAMETERS -------------------- 
