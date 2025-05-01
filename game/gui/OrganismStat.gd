extends Control

var _focused_organism: Slime

var _keys = ["hp", "energy", "food_eaten", "no_of_spawns", "spawn_wait_time", "generation", "age"]
var _fields: Dictionary = {}

func _process(_delta: float) -> void:
	if _focused_organism:
		_update_table_values()
	

func _add_table_field(key: String, value: String) -> void:
	var hbox = HBoxContainer.new()
	var keyLabel = Label.new()
	var valuelabel = Label.new()
	hbox.add_child(keyLabel)
	hbox.add_child(valuelabel)
	_fields[key] = valuelabel
	add_child(hbox)
	keyLabel.text = key
	keyLabel.custom_minimum_size.x = 60
	valuelabel.text = value

func _clear_table() -> void:
	for child in get_children():
			child.queue_free()

func _render_table() -> void:
	for key in _keys:
		_add_table_field(key, "-")
	if _focused_organism:
		_update_table_values()
			
func _update_table_values() -> void:
	for key in _keys:
		_fields[key].text = str(snapped(_focused_organism[key], 0.01))
		
func focus_on_organism(organism: Slime) -> void:
	_clear_table()
	_render_table()
	_focused_organism = organism
		
