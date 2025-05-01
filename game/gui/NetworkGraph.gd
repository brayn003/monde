extends Control

var focused_organism: Organism
var offset = Vector2(10, 10)
var zoom = Vector2(100, 200)

func _process(_delta: float) -> void:
	#if Engine.is_editor_hint():
	queue_redraw()

func _draw() -> void:
	#for i in 220:
		#if i % int(zoom / 10) == 0:
			#draw_line(offset + Vector2(i, 0), offset + Vector2(i, zoom), Color.DIM_GRAY)
			#draw_line(offset + Vector2(0, i), offset + Vector2(zoom, i), Color.DIM_GRAY)
	if focused_organism:
		var genome = focused_organism.genome
		
		for neuron in genome.neurons.values():
			draw_circle(offset + (neuron.position * zoom), 5, Color.WHITE)
			
		for link in genome.links.values() as Array[Link]:
			var from_pos = offset + genome.neurons[link.from_neuron_id].position * zoom
			var to_pos = offset + genome.neurons[link.to_neuron_id].position * zoom
			var color
			if not link.enabled:
				color = Color.DARK_RED
			else:
				color = Color.WHITE
			
			draw_line(from_pos, to_pos, color)

func focus_on_organism(organism: Organism) -> void:
	focused_organism = organism
	
