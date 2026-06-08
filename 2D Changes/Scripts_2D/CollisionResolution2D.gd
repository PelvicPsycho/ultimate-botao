extends Node
class_name CollisionResolution2D

@export var match_state: MatchState

var PhysicsObjects_List: Array[PhysicsObject2D]

var object_A: PhysicsObject2D
var object_B: PhysicsObject2D

@export var debug: bool
@export var debug_index: int

@export var simulation_Active: bool
@export var AI_Active: bool

#region simulation_AI Variables
var Sim_Controller_Object = preload("res://Componentes/Simulation_AI/Scenes/SimulationPitch.tscn")
@export var num_threads: int

# simulation to AI
var Sim_Controller_list: Array[SimulationController]
@export var IA_Contr: IA_Controller

# simulation to test
#@export var Sim_Controller: SimulationController

var pitch_state: PitchState

@export var list_polygons: Array[CollisionPolygon2D]
var list_polygons_points_0: PackedVector2Array
var list_polygons_points_1: PackedVector2Array
var list_polygons_points_2: PackedVector2Array
var list_polygons_points_3: PackedVector2Array

var list_walls_polygons_points: Array[PackedVector2Array] = []

var wall_collision_normal: Vector2
var wall_collision_depth: float

func _ready() -> void:
	var nodes = get_tree().get_nodes_in_group("PhysicsObjects")
	
	for object in nodes:
		PhysicsObjects_List.append(object)
	
	pitch_state = PitchState.new()
	
	var count = 0
	for object in PhysicsObjects_List:
		if object.is_in_group("Players"):
			object.Set_AI_Active(AI_Active)
			object.connect("ActionExecuted", Replicate_Action)
			
		object.index = count
		count += 1
	
	for point in list_polygons[0].polygon:
		list_polygons_points_0.append(list_polygons[0].to_global(point))

	for point in list_polygons[1].polygon:
		list_polygons_points_1.append(list_polygons[1].to_global(point))

	for point in list_polygons[2].polygon:
		list_polygons_points_2.append(list_polygons[2].to_global(point))

	for point in list_polygons[3].polygon:
		list_polygons_points_3.append(list_polygons[3].to_global(point))
	
	list_walls_polygons_points.append(list_polygons_points_0)
	list_walls_polygons_points.append(list_polygons_points_1)
	list_walls_polygons_points.append(list_polygons_points_2)
	list_walls_polygons_points.append(list_polygons_points_3)



func start_Collision_resulution() -> void:
	update_pitch_state_variables()
	
	if Sim_Controller_list.size() <= 0:
		create_all_simulations()
	
	for sim in Sim_Controller_list:
		sim.copy_pitch_state_variables(pitch_state)
		sim.simulation_ready = true

func Replicate_Action(index: int, velocity: Vector2, teamSide: int):	
	update_pitch_state_variables()
	
	for sim in Sim_Controller_list:
		if sim.debug:
			print("Sim index = ", sim.sim_index)
			sim.copy_pitch_state_variables(pitch_state)
			sim.Replicate_Action(index, velocity, teamSide)
			count_steps = 0
	
	#print("Original -------------------------------------------------------")

var count_steps = 0

func _physics_process(_delta: float) -> void:
	#
	# verify physic objects collisions
	collision_physics_object_resolution()
	#
	# update the movemente of all physic objects
	movement_update(0.016667)
	#
	# verify walls collisions
	collision_wall_resolution()
	#

	count_steps += 1


func create_all_simulations() -> void:
	if AI_Active:
		IA_Contr.SetPieceLists()
		
	#if simulation_Active == true:
		#var instance = Sim_Controller_Object.instantiate()
		#instance.global_position = self.global_position
		#
		#instance.copy_pitch_state_variables(pitch_state)
		#
		#instance.create_objects_copy(true)
		#
		#Sim_Controller_list.append(instance)
		#
		#add_child(instance)
	
	for i in num_threads:
		var instance = Sim_Controller_Object.instantiate()
		instance.global_position = self.global_position + Vector2(0, 1 * (1000 * (i)))
		print("instance position = ", instance.global_position)
		
		instance.copy_pitch_state_variables(pitch_state)
		
		instance.sim_index = i
		
		if debug_index == i:
			instance.create_objects_copy(false)
		else:
			instance.create_objects_copy(false)
			
		Sim_Controller_list.append(instance)
		
		add_child(instance)
		print("Num sim created = ", i)

func update_pitch_state_variables() -> void:
	pitch_state.all_physic_object_list.clear()
	
	for i in PhysicsObjects_List.size():
		var new_PhysicObject_Struct = PhysicObject_Struct.new()
		
		new_PhysicObject_Struct.index = PhysicsObjects_List[i].index
		new_PhysicObject_Struct.last_position = PhysicsObjects_List[i].global_position
		new_PhysicObject_Struct.current_velocity = PhysicsObjects_List[i].current_velocity
		
		new_PhysicObject_Struct.mass = PhysicsObjects_List[i].mass
		new_PhysicObject_Struct.friction = PhysicsObjects_List[i].friction
		new_PhysicObject_Struct.scale = PhysicsObjects_List[i].scale
		new_PhysicObject_Struct.radius = PhysicsObjects_List[i].radius
		
		if PhysicsObjects_List[i].is_in_group("Players"):
			new_PhysicObject_Struct.teamSide = PhysicsObjects_List[i].teamSide
			new_PhysicObject_Struct.is_a_player = true
			new_PhysicObject_Struct.level_force = PhysicsObjects_List[i].playerInfo_atual.level_force
			new_PhysicObject_Struct.level_force_weak = PhysicsObjects_List[i].playerInfo_atual.level_force_weak
			new_PhysicObject_Struct.level_force_strong = PhysicsObjects_List[i].playerInfo_atual.level_force_strong
			new_PhysicObject_Struct.current_min_force = PhysicsObjects_List[i].playerInfo_atual.get_min_force()
			new_PhysicObject_Struct.current_max_force = PhysicsObjects_List[i].playerInfo_atual.get_max_force()
			
		elif PhysicsObjects_List[i].is_in_group("Balls"):
			new_PhysicObject_Struct.is_a_player = false
		
		if PhysicsObjects_List[i].last_PhysicObject_collided != null:
			new_PhysicObject_Struct.last_touch_index = PhysicsObjects_List[i].last_PhysicObject_collided.index
		else:
			new_PhysicObject_Struct.last_touch_index = -1
		
		pitch_state.all_physic_object_list.append(new_PhysicObject_Struct) 
	
	pitch_state.home_score = match_state.homeScore
	pitch_state.away_score = match_state.awayScore
	
	pitch_state.can_score_goal = match_state.rallyCounter
	pitch_state.ball_possesion_counter = match_state.turnCounter
	pitch_state.current_team_playing = match_state.currentTurn


#region Physics Objects Collisions
func collision_physics_object_resolution() -> void:
	for object_A_index in range(PhysicsObjects_List.size()):
		object_A = PhysicsObjects_List[object_A_index]
		
		for object_B_index in range(object_A_index + 1, PhysicsObjects_List.size()):
			object_B = PhysicsObjects_List[object_B_index]
			
			if has_collision_physics_object(object_A, object_B):
				handle_physics_objects_collision(object_A, object_B)


func has_collision_physics_object(object_1: PhysicsObject2D, object_2: PhysicsObject2D) -> bool:
	var line_of_impact = object_2.global_position - object_1.global_position
	var distance = line_of_impact.length()
	
	var overlap = distance - (object_1.radius + object_2.radius)

	if overlap <= 0:
		object_1.Set_Last_PhysicObject_Collision(object_1.global_position + line_of_impact.normalized() * object_1.radius, object_2)
		object_2.Set_Last_PhysicObject_Collision(object_1.global_position + line_of_impact.normalized() * object_1.radius, object_1)
		return true
	else:
		return false

func has_collision_specific_Object(object_1: PhysicsObject2D) -> bool:
	for object_2_index in range(PhysicsObjects_List.size()):
		var object_2 = PhysicsObjects_List[object_2_index]
		
		if object_1.index != object_2.index:
			if has_collision_physics_object(object_1, object_2):
				return true
	return false


func handle_physics_objects_collision(object_1: PhysicsObject2D, object_2: PhysicsObject2D) -> void:
	var sum_masses = object_1.mass + object_2.mass
	var line_of_impact = object_2.position - object_1.position
	var distance = line_of_impact.length()
	var velocity_Diff = object_2.current_velocity - object_1.current_velocity
	
	# Handle Objects Overlap
	handle_physics_objects_inside_each_other(object_1, object_2, distance, line_of_impact)
	
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

func handle_physics_objects_inside_each_other(object_1: PhysicsObject2D, object_2: PhysicsObject2D, distance: float, line_of_impact: Vector2) -> void:
	var overlap = distance - (object_1.radius + object_2.radius)
	overlap = abs(overlap)

	line_of_impact = line_of_impact.normalized()
	
	object_1.global_position = object_1.global_position + ((-line_of_impact * (overlap * 0.51)))
	object_2.global_position = object_2.global_position + ((line_of_impact * (overlap * 0.51)))
	
#endregion

#region Physics Wall Collisions

func collision_wall_resolution() -> void:
	for i in range(PhysicsObjects_List.size()):
		object_A = PhysicsObjects_List[i]
		if has_collision_wall_polygons(object_A):
			handle_walls_collision(object_A)

func has_collision_wall_polygons(physic_object: PhysicsObject2D) -> bool:
	for polygon in list_walls_polygons_points:
		if physic_object.is_moving:
			if check_circle_polygon_collision(physic_object.global_position, physic_object.radius, polygon):
				return true
	return false

# if object has collided with a wall
# - corrects their position, so they don't stay inside a wall
# - Reflects the velocity vector
func handle_walls_collision(object_1: PhysicsObject2D) -> void:
	# Push the object out of the wall
	object_1.global_position += wall_collision_normal * wall_collision_depth
	
	# Reflect the velocity vector
	object_1.current_velocity = object_1.current_velocity.bounce(wall_collision_normal)

# Returns true if the circle intersects the polygon's boundary or interior
func check_circle_polygon_collision(circle_center: Vector2, circle_radius: float, list_polygons_points: PackedVector2Array) -> bool:
	if list_polygons_points.size() < 3:
		return false
		
	# Step 1: Check if the circle collides with any of the polygon's edges
	for i in range(list_polygons_points.size()):
		# Get a point from the polygon
		var current_point = list_polygons_points[i]
		
		# Get next point index, loop around to the first point if we are at the last index		
		# Get the next point after current_point from the polygon
		var next_point_index = (i + 1) % list_polygons_points.size()
		var next_point = list_polygons_points[next_point_index]
		
		# Find the closest point on this line segment to the circle's center
		var closest_point = get_closest_point_on_line(circle_center, current_point, next_point)

		# Calculate distance from circle center to the closest point
		var distance = circle_center.distance_to(closest_point)
		
		# If the distance is less than the radius, a collision has occurred
		if distance <= circle_radius:
			wall_collision_normal = (circle_center - closest_point).normalized()
			
			if wall_collision_normal == Vector2.ZERO:
				wall_collision_normal = (next_point - current_point).orthogonal().normalized()
			
			wall_collision_depth = circle_radius - distance
			return true
			
	# Step 2: interior check (handles when the circle is entirely inside the polygon)
	if Geometry2D.is_point_in_polygon(circle_center, list_polygons_points):
		print("Inside Polygon")
		return true
		
	return false


# Function to find the closest point on a line to a target point
func get_closest_point_on_line(target_point: Vector2, line_point_A: Vector2, line_point_B: Vector2) -> Vector2:
	# Get the direction vector from line_point_A to line_point_B
	var AB = line_point_B - line_point_A
	
	# Get the direction vector from line_point_A to target_point
	var AP = target_point - line_point_A
	
	# calculate the perpendicular vector of line_point_A and target_point on the AB vector
	# Project vector AP onto AB to find the scalar projection parameter 't'
	var t = AP.dot(AB) / AB.length_squared()
	
	# Clamp 't' to restrict the point to the segment boundaries [a, b]
	t = clamp(t, 0.0, 1.0)
	
	# Calculate the final coordinate on the segment
	return line_point_A + AB * t

#endregion

#region Movement
var global_Collision_Check_count: int

func movement_update(_delta: float) -> void:
	for i in range(PhysicsObjects_List.size()):
		# chama função do object que atualiza sua Velocity
		var new_velocity = PhysicsObjects_List[i].current_velocity * PhysicsObjects_List[i].friction;
		
		var mag = new_velocity.length()
		
		if mag < 20:
			PhysicsObjects_List[i].Set_Current_Velocity(Vector2.ZERO)
			PhysicsObjects_List[i].is_moving = false
		else:
			PhysicsObjects_List[i].Set_Current_Velocity(new_velocity)
			PhysicsObjects_List[i].is_moving = true
		
		if PhysicsObjects_List[i].is_moving:
			global_Collision_Check_count = 0
			
			# - Percorre o caminho que o objeto iria passar entre um frame e outro
			# - Caso tenha alguma colisão no meio do caminho, retorna a posição que a peça estava
			var new_Pos = verify_collision_between_objects_on_movement_line_LinearSearch(PhysicsObjects_List[i], 10.0, _delta)
			

			# Atualiza a posição do objeto
			PhysicsObjects_List[i].global_position = new_Pos



# Faz verificações de colisões entre a posição atual do objeto e a sua próxima posição (posição depois de se mover no proximo frame)
# "subdivisionsNumber" é a quantidade de verifições
# Usa a lógica de uma busca linear
func verify_collision_between_objects_on_movement_line_LinearSearch(object_1: PhysicsObject2D, subdivisionsNumber: float, _delta: float) -> Vector2:
	var inicial_Pos = object_1.global_position
	var final_Pos = object_1.global_position + (object_1.current_velocity * _delta)
	
	# verifica se o movimento é menor que seu proprio raio
	# caso for, não é necessario fazer a verificação de colisão
	if inicial_Pos.distance_to(final_Pos) < object_1.radius:
		return final_Pos

	var result_Pos = final_Pos
	var lerp_step = 1.0 / subdivisionsNumber

	for i in range(0.0, subdivisionsNumber + 1):
		var lerp_value = lerp_step * i
		var current_Pos = inicial_Pos.lerp(final_Pos, lerp_value)

		# posiciono o objeto na posição nova
		object_1.global_position = current_Pos
		
		# atualizo as informações do shapecast
		object_1.shapecast_physics_objects.force_shapecast_update()
		object_1.shapecast_walls.force_shapecast_update()
		
		global_Collision_Check_count += 1
		
		# Verifico se esta colidindo com outro objeto
		if has_collision_specific_Object(object_1) or has_collision_wall_polygons(object_1): # Colidiu com algo
			result_Pos = current_Pos
			
			# retorno a posição da colisão
			return result_Pos
	
	object_1.global_position = inicial_Pos
	return result_Pos

#endregion
