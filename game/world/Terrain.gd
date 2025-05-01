class_name Terrain
extends TileMapLayer

var fnl = FastNoiseLite.new()

func _ready() -> void:
	#_ready_map()
	pass

func _ready_map() -> void:
	randomize()
	fnl.seed = randi()
	fnl.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fnl.frequency = 0.004
	for x in range(-250, 250):
		for y in range(-150, 150):
			var noise_val = fnl.get_noise_2d(x, y)
			if noise_val > 0.5:
				set_cell(Vector2i(x, y), 0, Vector2i(1, 1))
