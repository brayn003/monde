extends Control

var _selected_entity: Creature

var _keys = [
	"_hp", 
	"_energy", 
	"_age",
	"_food_count", 
	"_food_wait_time", 
	"_offspring_count", 
	"_offspring_wait_time", 
	"generation"]
var _fields: Dictionary = {}

func _process(_delta: float) -> void:
	if _selected_entity:
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
	keyLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	valuelabel.text = value
	valuelabel.custom_minimum_size.x = 30
	#valuelabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _clear_table() -> void:
	for child in get_children():
			child.queue_free()

func _render_table() -> void:
	for key in _keys:
		_add_table_field(key, "-")
	if _selected_entity:
		_update_table_values()
			
func _update_table_values() -> void:
	for key in _keys:
		_fields[key].text = str(snapped(_selected_entity[key], 0.01))
		
func select_entity(entity: Creature) -> void:
	_clear_table()
	_render_table()
	_selected_entity = entity
		
