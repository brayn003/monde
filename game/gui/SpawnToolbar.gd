extends Control

@onready var _piki_btn = $C/PikiButton
@onready var _aiko_btn = $C/AikoButton

func _ready() -> void:
	_piki_btn.toggle_mode = true
	_piki_btn.pressed.connect(
		func (): _on_button_toggled(Constants.Family.PIKI))
	
	_aiko_btn.toggle_mode = true
	_aiko_btn.pressed.connect(
		func (): _on_button_toggled(Constants.Family.AIKO))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index != MOUSE_BUTTON_LEFT:
			_emit_clicked_build_spawner(Constants.Family.NONE)
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_emit_clicked_build_spawner(Constants.Family.NONE)

func _on_button_toggled(family: Constants.Family) -> void:
	_emit_clicked_build_spawner(family)

func _emit_clicked_build_spawner(family: Constants.Family) -> void:
	var gui: Gui = get_parent()
	gui.clicked_build_spawner.emit(family)
