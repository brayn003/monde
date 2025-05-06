class_name Piki
extends Creature

func _init() -> void:
	_max_hp = Constants.PIKI_MAX_HP
	_initial_energy = Constants.PIKI_INITIAL_ENERGY
	_max_energy = Constants.PIKI_MAX_ENERGY
	_clock_speed = Constants.PIKI_CLOCK_SPEED
	_max_age = Constants.PIKI_MAX_AGE
	_offspring_wait = Constants.PIKI_OFFSPRING_WAIT
	_offspring_initial_wait = Constants.PIKI_OFFSPRING_INITIAL_WAIT
	_offspring_energy_cost = Constants.PIKI_OFFSPRING_ENERGY_COST
	family = Constants.Family.PIKI

func _ready() -> void:
	super()
	add_to_group("pikis")
