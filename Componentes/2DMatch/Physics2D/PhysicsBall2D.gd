extends PhysicsObject2D
class_name PhysicsBall2D

var lastTouch: PhysicsPlayer2D

@export var debug: bool = true

#region Movement
var posicao_atual: Vector2
var is_moving: bool

func move_object(_delta: float) -> void:
	var friction_value = lerpf(friction_min, friction_max, friction)
	current_velocity += -current_velocity/2 * friction_value;
	
	current_velocity = Vector2(current_velocity.x, current_velocity.y)
	
	#if debug:
		#Draw3d.line(position, position + current_velocity, Color.BLUE, 0.05)
	
	if abs(current_velocity.x) < 0.1 && abs(current_velocity.y) < 0.1:
		current_velocity = Vector2.ZERO
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
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	
	lastTouch = object_collided
	print("lastTouch name = ", lastTouch.name)
	print("collision_position = ", last_PhysicObject_collision_position)
#endregion
