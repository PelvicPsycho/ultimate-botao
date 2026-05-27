extends PhysicsObject2D
class_name PhysicsBall2D_Simulation_NoVisuals

var lastTouch: PhysicsPlayer2D_Simulation_NoVisuals

@export var shapecast_goals: ShapeCast2D

var index: int

@export var debug: bool = true

enum TeamSide {HOME, AWAY}
@export var teamSide: TeamSide

@export var basic_min_force: float = 100.0
@export var basic_max_force: float = 1000.0
@export var basic_mass: float = 5.0
@export var basic_friction: float = 0.98
@export var basic_scale: float = 1

@export var Object_Radius: Node2D

func _ready() -> void:
	radius = (global_position - Object_Radius.global_position).length()


#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	
	lastTouch = object_collided
	#print("lastTouch object name = ", lastTouch.name)
	#print("lastTouch team name = ", lastTouch.team.name)
#endregion
