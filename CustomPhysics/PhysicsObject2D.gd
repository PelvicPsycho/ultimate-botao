extends CharacterBody2D
class_name PhysicsObject2D

@export var shapecast_physics_objects: ShapeCast2D
@export var shapecast_walls: ShapeCast2D

#@export var acceleration: Vector2 = Vector2.ZERO
@export var mass: float = 5
@export_range(0, 1) var friction: float = 0.98
#@export var friction_min: float = 0.01
#@export var friction_max: float = 0.2

var radius: float

var is_moving: bool

# Runtime Variables
var current_velocity: Vector2 = Vector2.ZERO
var last_velocity: Vector2 = Vector2.ZERO

var last_position: Vector2 = position

var last_position_without_collision: Vector2

func _process(_delta: float) -> void:
	pass

func _physics_process(delta):
	pass

func Move_Object(_delta: float) -> void:
	pass

func Set_Current_Velocity(new_velocity: Vector2) -> void:
	current_velocity = new_velocity

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	pass
	
	
