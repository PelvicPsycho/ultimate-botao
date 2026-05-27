extends PhysicsObject2D
class_name PhysicsBall2D

var lastTouch: PhysicsPlayer2D

var index: int

@export var debug: bool = true

@export var basic_min_force: float = 100.0
@export var basic_max_force: float = 1000.0
@export var basic_mass: float = 5.0
@export var basic_friction: float = 0.98
@export var basic_scale: float = 1

@export var Object_Radius: Node2D

func _ready() -> void:
	radius = (global_position - Object_Radius.global_position).length()

#region Movement

func move_object(_delta: float) -> void:
	#var friction_value = lerpf(friction_min, friction_max, friction)
	var new_velocity = current_velocity * friction;
	
	Set_Current_Velocity(new_velocity)
	
	#print("Ball Velocity = ", current_velocity.length())
	
	if abs(current_velocity.x) < 10 && abs(current_velocity.y) < 10:
		Set_Current_Velocity(Vector2.ZERO)
		is_moving = false
	else:
		is_moving = true
		
	if !is_moving:
		return
	
	#last_position = position
	#var newPos = position + (current_velocity * _delta)
	#position = newPos

#endregion

#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	
	lastTouch = object_collided
	print("lastTouch object name = ", lastTouch.name)
	print("lastTouch team name = ", lastTouch.team.name)
#endregion
