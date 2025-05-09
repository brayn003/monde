extends Node

var rng = RandomNumberGenerator.new()

func random_f() -> float:
	rng.randomize()
	return rng.randf() 

func random_f_range(start: float, end: float) -> float:
	rng.randomize()
	return rng.randf_range(start, end) 

func random_i_range(start: int, end: int) -> int:
	rng.randomize()
	return rng.randi_range(start, end) 

func random_choice(arr: Array):
	var pick_index = random_i_range(0, arr.size() - 1)
	return arr[pick_index]

func random_rotation() -> float:
	return rng.randf_range(-PI, PI)

func gauss(deviation) -> float:
	rng.randomize()
	return rng.randfn(0.0, deviation)

func merge_dicts(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	var new_dict = dict1.duplicate(true)
	for key in dict2.keys():
		if not new_dict.has(key):
			new_dict[key] = dict2[key]
	return new_dict

func sort_and_remove_duplicates(arr: Array) -> Array:
	arr.sort()
	var new_array = []
	var last_value: int
	for value in arr:
		if not last_value == value:
			new_array.append(value)
		last_value = value
	return new_array

func arr_unique(arr: Array) -> Array:
	var unique: Array = []
	for item in arr:
		if not unique.has(item):
			unique.append(item)
	return unique

func math_factorial(num: int) -> int:
	if num == 0 or num == 1: 
		return 1
	return num * math_factorial(num - 1)

func math_combination(n: int, r: int):
	return int(float(
		math_factorial(n)) / (math_factorial(r) * math_factorial(n - r)))
