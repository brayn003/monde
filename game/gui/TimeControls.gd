extends CenterContainer

var time_scale: float = 1.0

func _ready() -> void:
	$HBoxContainer/MarginContainer/TimeSlider.value = time_scale
	$HBoxContainer/Label.text = str(time_scale)


func _on_time_slider_value_changed(value: float) -> void:
	time_scale = value
	$HBoxContainer/Label.text = str(time_scale)
	if Engine.time_scale != time_scale:
		Engine.time_scale = time_scale
