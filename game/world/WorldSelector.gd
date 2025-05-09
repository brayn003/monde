class_name WorldSelector
extends Node2D

signal clicked(entity: Creature)

var _pool: Array[Creature] = []
var _radius: float = 0.0

var _sort_wait: float = 0.3
var _curr_sort_wait: float = 0.0

@onready var _area : Area2D = $Area
@onready var _collision: CollisionShape2D = $Area/Collision

func _init() -> void:
	_radius = Constants.WORLD_SELECTOR_SIZE / 2

func _ready() -> void:
	_collision.shape.radius = _radius
	_area.body_entered.connect(_on_area_body_entered)
	_area.body_exited.connect(_on_area_body_exited)

func _input(event: InputEvent) -> void:
	_input_select_entity(event)

func _input_select_entity(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			clicked.emit(_pool[0] if _pool.size() > 0 else null)
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			clicked.emit(null)
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
		clicked.emit(null)

func _physics_process(delta: float) -> void:
	_process_sort_pool(delta)

func _process_sort_pool(delta: float) -> void:
	_curr_sort_wait += delta
	if _curr_sort_wait >= _sort_wait:
		_pool.sort_custom(func(a: Creature, b: Creature): 
			return a.body.position.distance_to(position) < b.body.position.distance_to(position))
		_curr_sort_wait = 0.0

func _on_area_body_entered(body: Node2D) -> void:
	if body is CreatureBody:
		_pool.append(body.get_parent())

func _on_area_body_exited(body: Node2D) -> void:
	if body is CreatureBody:
		_pool.erase(body.get_parent())

func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, Color.GRAY, false)
