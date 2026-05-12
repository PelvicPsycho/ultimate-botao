extends CharacterBody3D
class_name PhysicsObject

@export var shapecast_physics_objects: ShapeCast3D
@export var shapecast_walls: ShapeCast3D

#@export var acceleration: Vector3 = Vector3.ZERO
@export var mass: float = 5
@export_range(0, 1) var friction: float = 0.1
@export var friction_min: float = 0.01
@export var friction_max: float = 0.2



# Runtime Variables
var current_velocity: Vector3 = Vector3.ZERO
var last_velocity: Vector3 = Vector3.ZERO

var last_position: Vector3 = position

var last_position_without_collision: Vector3

func _process(_delta: float) -> void:
	pass

func _physics_process(delta):
	pass

func Move_Object(_delta: float) -> void:
	pass

func Set_Current_Velocity(new_velocity: Vector3) -> void:
	pass

func Set_Last_PhysicObject_Collision(collision_position: Vector3, object_collided: PhysicsObject) -> void:
	pass
	
	
