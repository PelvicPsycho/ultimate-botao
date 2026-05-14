extends PhysicsObject
class_name PhysicsBall

var lastTouch: PhysicsPlayer

@export var debug: bool = true

#region Movement
var posicao_atual: Vector3
var is_moving: bool

func move_object(_delta: float) -> void:
	var friction_value = lerpf(friction_min, friction_max, friction)
	var new_velocity = current_velocity + (-current_velocity/2 * friction_value);
	
	Set_Current_Velocity(new_velocity)

	if debug:
		Draw3d.line(position, position + current_velocity, Color.BLUE, 0.05)
	
	if abs(current_velocity.x) < 0.1 && abs(current_velocity.z) < 0.1:
		Set_Current_Velocity(Vector3.ZERO)
		is_moving = false
	else:
		is_moving = true
		
	if !is_moving:
		return
	
	last_position = position
	var newPos = position + (current_velocity * _delta)
	position = newPos

#endregion

#region collisions
var last_PhysicObject_collided: PhysicsObject
var last_PhysicObject_collision_position: Vector3

func Set_Last_PhysicObject_Collision(collision_position: Vector3, object_collided: PhysicsObject) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	
	lastTouch = object_collided
	print("lastTouch name = ", lastTouch.name)
	print("collision_position = ", last_PhysicObject_collision_position)
#endregion
