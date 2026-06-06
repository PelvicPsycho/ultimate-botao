extends Node
class_name PhysicObject_Struct

var is_a_player: bool

var index: int

var mass: float
var friction: float
var min_force: float
var max_force: float
var scale: Vector2

var last_touch_index: int
var last_touch_position: Vector2
var last_position: Vector2
var current_velocity: Vector2
var teamSide: int

var is_moving: bool

var radius: float

@export var current_min_force: float = 100.0
@export var current_max_force: float = 1000.0
@export var level_force: int # nivel de força da peça (0 a 10)
@export var level_force_weak: int = 3  # Abaixo deste valor = FRACO
@export var level_force_strong: int = 7  # Acima deste valor = FORTE
