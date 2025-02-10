extends Camera2D

const min_zoom = 0.1
const max_zoom = 4

var touch_sensitivity = 40
var pan_speed = 8
var zoom_speed = 1

func _ready() -> void:
	position = get_viewport_rect().size / 2
	zoom = Vector2(1.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventPanGesture:
		position += event.delta * touch_sensitivity
	if event is InputEventMagnifyGesture:
		var current_zoom = zoom.x
		var updated_zoom = clamp(current_zoom * event.factor, min_zoom, max_zoom)
		var mouse_pos := get_global_mouse_position()
		zoom = Vector2(updated_zoom, updated_zoom)
		var new_mouse_pos := get_global_mouse_position()
		position += mouse_pos - new_mouse_pos
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_out"):
		update_zoom()
	if event.is_action_pressed("camera_zoom_in"):
		update_zoom()
		
#func _process(_delta):
	#if Input.is_action_pressed("camera_pan_up"):
		#position.y -= pan_speed
	#if Input.is_action_pressed("camera_pan_down"):
		#position.y += pan_speed
	#if Input.is_action_pressed("camera_pan_left"):
		#position.x -= pan_speed
	#if Input.is_action_pressed("camera_pan_right"):
		#position.x += pan_speed
	

func update_zoom():
	zoom += clamp(zoom_speed, min_zoom, max_zoom)
