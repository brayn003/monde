class_name Aiko
extends Creature

func _init() -> void:
	_max_hp = Constants.AIKO_MAX_HP
	_initial_energy = Constants.AIKO_INITIAL_ENERGY
	_max_energy = Constants.AIKO_MAX_ENERGY
	_clock_speed = Constants.AIKO_CLOCK_SPEED
	_max_age = Constants.AIKO_MAX_AGE
	family = Constants.Family.AIKO
	
func _ready() -> void:
	super()
	add_to_group("aikos")

func _on_body_body_entered(input_body: Node) -> void:
	if input_body is PikiBody:
		input_body.get_parent()._deduct_hp(10.0)
		_food_count += 1
		_energy += 120
	#elif body is ConsumableBody:
		#food_eaten += 1
		#energy += 5
