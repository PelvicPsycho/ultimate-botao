extends PhysicsObject2D
class_name PhysicsBall2D_Simulation

@export var lastTouch: PhysicsPlayer2D_Simulation

@export var debug: bool = true

#region Simulation Needed Variables
#enum TeamSide {HOME, AWAY}
#@export var teamSide: TeamSide

var radius: float

@export var Object_Radius: Node2D

@export var shapecast_goals: ShapeCast2D
#endregion


func _ready() -> void:
	radius = (global_position - Object_Radius.global_position).length()


#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	
	lastTouch = object_collided
#endregion
