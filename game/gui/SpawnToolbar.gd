extends Control

@onready var _piki_btn = $C/PikiButton
@onready var _aiko_btn = $C/AikoButton

func _ready() -> void:
	_piki_btn.toggle_mode = true
	_piki_btn.toggled.connect(
		func (t): _on_button_toggled(t, Constants.Family.PIKI))
	
	_aiko_btn.toggle_mode = true
	_aiko_btn.toggled.connect(
		func (t): _on_button_toggled(t, Constants.Family.AIKO))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index != MOUSE_BUTTON_LEFT:
			_emit_toggled_spawn(Constants.Family.NONE)
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_emit_toggled_spawn(Constants.Family.NONE)

func _on_button_toggled(toggled_on: bool, family: Constants.Family) -> void:
	if toggled_on:
		_emit_toggled_spawn(family)

func _emit_toggled_spawn(family: Constants.Family) -> void:
	var gui: Gui = get_parent()
	gui.toggled_spawn.emit(family)
