extends Node

@export var PhysicsObjects_List: Array[PhysicsObject] = []

var object_A: PhysicsObject
var object_B: PhysicsObject

@export var debug: bool

func _ready() -> void:
	#collision_physics_object_resolution()
	pass

func _physics_process(delta: float) -> void:
	#
	# verify physic objects collisions
	collision_physics_object_resolution()
	#
	
	#
	# update the movemente of all physic objects
	movement_update(delta)
	#
	
	#
	# verify walls collisions
	collision_wall_resolution(delta)
	#
	
	#
	# verify if objects are still colliding or inside other objects/walls
	#handle_physics_objects_inside_each_other()
	#

#region Physics Objects Collisions
func collision_physics_object_resolution() -> void:
	for i in range(PhysicsObjects_List.size()):
		object_A = PhysicsObjects_List[i]
		for j in range(i + 1, PhysicsObjects_List.size()):
			object_B = PhysicsObjects_List[j]
			if has_collision_physics_object(object_A, object_B):
				handle_physics_objects_collision(object_A, object_B)

func has_collision_physics_object(object_1: PhysicsObject, object_2: PhysicsObject) -> bool:
	object_1.shapecast_physics_objects.force_shapecast_update()
	
	if object_1.shapecast_physics_objects.is_colliding():
		for i in object_1.shapecast_physics_objects.get_collision_count():
			var collider = object_1.shapecast_physics_objects.get_collider(i)
			if collider == object_2:
				object_1.Set_Last_PhysicObject_Collision(object_1.shapecast_physics_objects.get_collision_point(i), object_2)
				object_2.Set_Last_PhysicObject_Collision(object_1.shapecast_physics_objects.get_collision_point(i), object_1)
				return true
	else:
		object_1.last_position_without_collision = object_1.global_position
		
	return false

func handle_physics_objects_collision(object_1: PhysicsObject, object_2: PhysicsObject) -> void:
	var sum_masses = object_1.mass + object_2.mass
	var line_of_impact = object_2.position - object_1.position
	var distance = line_of_impact.length()
	var velocity_Diff = object_2.current_velocity - object_1.current_velocity
	
	# --------------------
	# Object 1
	var num_object_1 = (2 * object_2.mass) * velocity_Diff.dot(line_of_impact)
	var den = sum_masses * (distance * distance)
	
	var velocity_change_object_1 = line_of_impact * (num_object_1 / den)
	object_1.current_velocity += velocity_change_object_1
	
	# --------------------
	# Object 2
	velocity_Diff *= -1
	line_of_impact *= -1
	var num_object_2 = (2 * object_1.mass) * velocity_Diff.dot(line_of_impact)
	
	var velocity_change_object_2 = line_of_impact * (num_object_2 / den)
	object_2.current_velocity += velocity_change_object_2

#func handle_physics_objects_inside_each_other(object_1: PhysicsObject, object_2: PhysicsObject) -> void:
	#pass
#endregion

#region Physics Wall Collisions
func collision_wall_resolution(delta: float) -> void:
	for i in range(PhysicsObjects_List.size()):
		object_A = PhysicsObjects_List[i]
		if has_collision_wall(object_A):
			handle_walls_collision(object_A)
			object_A.move_object(delta)

func has_collision_wall(physic_object: PhysicsObject) -> bool:
	physic_object.shapecast_walls.force_shapecast_update()
	
	if physic_object.shapecast_walls.is_colliding():
		for i in physic_object.shapecast_walls.get_collision_count():
			var collider = physic_object.shapecast_walls.get_collider(i)
			print("Collision: ", collider.name)
			return true
	
	return false
	
func handle_walls_collision(physic_object: PhysicsObject) -> void:
	# Get the normal of the wall we hit
	var normal = physic_object.shapecast_walls.get_collision_normal(0)
	
	# Reflect the velocity vector
	physic_object.current_velocity = physic_object.current_velocity.bounce(normal)
	
	Draw3d.line(physic_object.shapecast_walls.get_collision_point(0) + Vector3(0, 0.1, 0), physic_object.shapecast_walls.get_collision_point(0) + (normal) + Vector3(0, 0.1, 0), Color.YELLOW, 1)
	
	#Draw3d.line(physic_object.last_position + Vector3(0, 0.1, 0), physic_object.last_position + physic_object.current_velocity + Vector3(0, 0.1, 0), Color.BLUE, 1)
#endregion

#region Fixing Tunneling
func check_line_of_sight(delta: float, object_1: PhysicsObject):
	var target_position = object_1.position + (object_1.current_velocity * delta)

	#object_1.raycast.rayforce_raycast_update()
#
	#if object_1.raycast.is_colliding():
		#for i in object_1.shapecast_physics_objects.get_collision_count():
			#var collider = object_1.shapecast_physics_objects.get_collider(i)
			#print("Hit something at: ", collider.position)
			#print("Collider: ", collider.collider)
	#else:
		#print("Clear path between points.")
#endregion

#region Movement
func movement_update(delta: float) -> void:
	for i in range(PhysicsObjects_List.size()):
		#check_line_of_sight(delta, PhysicsObjects_List[i])
		PhysicsObjects_List[i].move_object(delta)
#endregion
