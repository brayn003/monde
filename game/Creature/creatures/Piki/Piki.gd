class_name Piki
extends Creature

func _init() -> void:
	_max_hp = Constants.PIKI_MAX_HP
	_initial_energy = Constants.PIKI_INITIAL_ENERGY
	_max_energy = Constants.PIKI_MAX_ENERGY
	_clock_speed = Constants.PIKI_CLOCK_SPEED
	family = Constants.Family.PIKI

func _ready() -> void:
	super()
	add_to_group("pikis")