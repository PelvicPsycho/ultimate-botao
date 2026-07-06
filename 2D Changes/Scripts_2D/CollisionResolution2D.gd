extends Node
class_name CollisionResolution2D

@export var match_state: MatchState_AI

var PhysicsObjects_List: Array[PhysicsObject2D]

var object_A: PhysicsObject2D
var object_B: PhysicsObject2D

var show_play_simulation_result_index: int
var show_play_simulation_result: bool
var AI_Active: bool

var Sim_Controller_Object = preload("res://Componentes/Simulation_AI/Scenes/SimulationPitch2D.tscn")
@export var num_threads: int

# simulation to AI
var Sim_Controller_list: Array[SimulationController]
@export var IA_Contr: IA_Controller

var current_pitch_state: PitchState

var all_physicObjects_loaded: bool = false
var current_pitch_state_loaded: bool = false

@export var TopWall_Line: Line2D
@export var BotWall_Line: Line2D
@export var HomeGoalWall_Line: Line2D
@export var AwayGoalWall_Line: Line2D

var TopWall_Line_points: PackedVector2Array
var BotWall_Line_points: PackedVector2Array
var HomeGoalWall_Line_points: PackedVector2Array
var AwayGoalWall_Line_points: PackedVector2Array

var wall_collision_normal: Vector2
var wall_collision_depth: float

var count_steps = 0

@export var Pitch_Middle_Point: Node2D
#var middle_x: int
#var middle_y: int

func _ready() -> void:
	if not PvPManager.isPvpMatch:
		AI_Active = true
	else:
		AI_Active = false
		
	var nodes = get_tree().get_nodes_in_group("PhysicsObjects")
	for object in nodes:
		PhysicsObjects_List.append(object)
		
	print("number of players = ", PhysicsObjects_List.size())
	
	current_pitch_state = PitchState.new()
	current_pitch_state_loaded = false
	all_physicObjects_loaded = false
	
	var count = 0
	for object in PhysicsObjects_List:
		if object.is_in_group("Players"):
			object.Set_AI_Active(AI_Active)
			object.connect("ActionExecuted", Replicate_Action)
			
		object.index = count
		count += 1
	
	Set_Pitch_Simulation_Lines()


func Set_Pitch_Simulation_Lines() -> void:
	# Physics Objects
	#list_walls_lines_points.clear()
	TopWall_Line_points.clear()
	BotWall_Line_points.clear()
	HomeGoalWall_Line_points.clear()
	AwayGoalWall_Line_points.clear()
	
	for point in TopWall_Line.points:
		TopWall_Line_points.append(TopWall_Line.to_global(point))

	for point in BotWall_Line.points:
		BotWall_Line_points.append(BotWall_Line.to_global(point))

	for point in HomeGoalWall_Line.points:
		HomeGoalWall_Line_points.append(HomeGoalWall_Line.to_global(point))

	for point in AwayGoalWall_Line.points:
		AwayGoalWall_Line_points.append(AwayGoalWall_Line.to_global(point))

func _physics_process(_delta: float) -> void:
	set_pitch_state_variables_from_PhysicsObjects()
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
	
	# Set Physical objects positions from PitchState
	update_PhysicsObjects_from_CurrentPitchState()
	
func start_Collision_resulution(_ai_active: bool, _show_play_simulation_result: bool, _show_play_simulation_result_index: int) -> void:
	AI_Active = _ai_active
	show_play_simulation_result = _show_play_simulation_result
	show_play_simulation_result_index = _show_play_simulation_result_index
	
	set_pitch_state_variables_from_PhysicsObjects()
	
	if Sim_Controller_list.size() <= 0:
		create_all_simulations()
	
	for sim in Sim_Controller_list:
		Update_pitch_state_variables_on_Simulations(current_pitch_state.current_team_playing)
		sim.simulation_ready = true

func set_pitch_state_variables_from_PhysicsObjects() -> void:
	if current_pitch_state.all_physic_object_list != null:
		current_pitch_state.all_physic_object_list.clear()
	
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
			
			new_PhysicObject_Struct.atrai_bola_ativo = PhysicsObjects_List[i].playerInfo_atual.atrai_bola_ativo
			new_PhysicObject_Struct.atrai_bola_forca = PhysicsObjects_List[i].playerInfo_atual.atrai_bola_forca
			
		elif PhysicsObjects_List[i].is_in_group("Balls"):
			new_PhysicObject_Struct.is_a_player = false

		
		#if PhysicsObjects_List[i].last_PhysicObject_collided != null:
			#new_PhysicObject_Struct.last_touch_index = PhysicsObjects_List[i].last_PhysicObject_collided.index
		#else:
			#new_PhysicObject_Struct.last_touch_index = -1
		
		current_pitch_state.all_physic_object_list.append(new_PhysicObject_Struct) 
	
	reset_last_touch_of_all_pieces()
	
	current_pitch_state.home_score = match_state.homeScore
	current_pitch_state.away_score = match_state.awayScore
	
	current_pitch_state.middle_x = Pitch_Middle_Point.global_position.x
	current_pitch_state.middle_y = Pitch_Middle_Point.global_position.y
	
	current_pitch_state.can_score_goal = match_state.rallyCounter
	current_pitch_state.ball_possesion_counter = match_state.turnCounter
	current_pitch_state.current_team_playing = match_state.get_current_turn_int()
	
	current_pitch_state_loaded = true

func reset_last_touch_of_all_pieces() -> void:
	for object in current_pitch_state.all_physic_object_list:
		object.last_touch_index = -1
		object.last_touch_position = Vector2.ZERO

func create_all_simulations() -> void:
	# If AI is active, call the AI controller and update it with all pieces
	if AI_Active:
		IA_Contr.SetPieceLists()
	
	# Use centralized concurrency decision from ConcurrencyMgr autoload.
	# On web (nothreads) this returns 1; on desktop native it returns cores - 2 (min 1, max 8).
	num_threads = ConcurrencyMgr.get_effective_worker_count()
	print("Simulation workers: ", num_threads, " (mode: ", "THREADED" if ConcurrencyMgr.is_threaded() else "TIME_SLICED", ")")
	
	# Create all simulations
	for i in num_threads:
		var instance = Sim_Controller_Object.instantiate()
		instance.global_position = self.global_position #+ Vector2(0, 1 * (1000 * (i)))
		
		# Set all physics variables
		instance.Set_Pitch_Simulation_Lines()
		
		# Set the simulation 'PitchState' with 'CollisionResolution' 'PitchState'
		instance.update_pitch_state_variables(current_pitch_state)
		instance.sim_index = i
		
		# Create all physical objects on the simulation
		# The index selected will show a visible prediction of last play of game
		if show_play_simulation_result_index == i and show_play_simulation_result:
			instance.create_objects_copy(true)
		else:
			instance.create_objects_copy(false)
		
		instance.update_visuals_position()
		
		Sim_Controller_list.append(instance)
		add_child(instance)

func Update_pitch_state_variables_on_Simulations(teamSide: int) -> void:
	current_pitch_state.current_team_playing = teamSide
	for sim in Sim_Controller_list:
		sim.update_pitch_state_variables(current_pitch_state)

func update_PhysicsObjects_from_CurrentPitchState() -> void:
	for object in current_pitch_state.all_physic_object_list:
		# Position
		PhysicsObjects_List[object.index].global_position = object.last_position
		
		# Velocity
		PhysicsObjects_List[object.index].current_velocity = object.current_velocity
		
		# Movement state — needed by ball rolling shader & other visuals
		PhysicsObjects_List[object.index].is_moving = object.is_moving
		
		# Other Physics Variables
		PhysicsObjects_List[object.index].mass = object.mass
		PhysicsObjects_List[object.index].friction = object.friction
		PhysicsObjects_List[object.index].scale = object.scale
		PhysicsObjects_List[object.index].radius = object.radius
		
		# force
		if object.is_a_player:
			PhysicsObjects_List[object.index].playerInfo_atual.level_force = object.level_force
			PhysicsObjects_List[object.index].playerInfo_atual.current_min_force = PhysicsObjects_List[object.index].playerInfo_atual.get_min_force()
			PhysicsObjects_List[object.index].playerInfo_atual.current_max_force = PhysicsObjects_List[object.index].playerInfo_atual.get_max_force()
		
		# Last piece collided
		if object.last_touch_index >= 0:
			PhysicsObjects_List[object.index].Set_Last_PhysicObject_Collision(object.last_touch_position, PhysicsObjects_List[object.last_touch_index])
		
		object.last_touch_position = Vector2.ZERO
		object.last_touch_index = -1

func Replicate_Action(index: int, velocity: Vector2, teamSide: int):
	set_pitch_state_variables_from_PhysicsObjects()
	
	for sim in Sim_Controller_list:
		if sim.show_play_simulation_result:
			Update_pitch_state_variables_on_Simulations(teamSide)
			sim.Replicate_Action(index, velocity, teamSide)
			count_steps = 0

#region Physics Objects Collisions
func collision_physics_object_resolution() -> void:
	var size = current_pitch_state.all_physic_object_list.size()
	for object_A_index in range(size):
		var object_A = current_pitch_state.all_physic_object_list[object_A_index]
		for object_B_index in range(object_A_index + 1, size):
			var object_B = current_pitch_state.all_physic_object_list[object_B_index]
			if has_collision_physics_object(object_A, object_B, true):
				handle_physics_objects_collision(object_A, object_B)

func has_collision_physics_object(object_1: PhysicObject_Struct, object_2: PhysicObject_Struct, change_values: bool) -> bool:
	var line_of_impact = object_2.last_position - object_1.last_position
	var radius_sum = object_1.radius + object_2.radius

	if line_of_impact.length_squared() <= radius_sum * radius_sum:
		if change_values:
			var normal = line_of_impact.normalized()
			
			object_1.last_touch_index = object_2.index
			object_1.last_touch_position = object_1.last_position + normal * object_1.radius
			
			object_2.last_touch_index = object_1.index
			object_2.last_touch_position = object_1.last_position + normal * object_1.radius
		return true
	else:
		return false



func handle_physics_objects_collision(object_1: PhysicObject_Struct, object_2: PhysicObject_Struct) -> void:
	var sum_masses = object_1.mass + object_2.mass
	var line_of_impact = object_2.last_position - object_1.last_position
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
	
	current_pitch_state.all_physic_object_list[object_1.index] = object_1
	
	# --------------------
	# Object 2
	velocity_Diff *= -1
	line_of_impact *= -1
	var num_object_2 = (2 * object_1.mass) * velocity_Diff.dot(line_of_impact)
	
	var velocity_change_object_2 = line_of_impact * (num_object_2 / den)
	object_2.current_velocity += velocity_change_object_2
	
	current_pitch_state.all_physic_object_list[object_2.index] = object_2

func handle_physics_objects_inside_each_other(object_1: PhysicObject_Struct, object_2: PhysicObject_Struct, distance: float, line_of_impact: Vector2) -> void:
	var overlap = distance - (object_1.radius + object_2.radius)
	overlap = abs(overlap)

	line_of_impact = line_of_impact.normalized()

	object_1.last_position = object_1.last_position + ((-line_of_impact * (overlap * 0.51)))
	object_2.last_position = object_2.last_position + ((line_of_impact * (overlap * 0.51)))

	current_pitch_state.all_physic_object_list[object_1.index] = object_1
	current_pitch_state.all_physic_object_list[object_2.index] = object_2

func has_collision_specific_Object(object_1: PhysicObject_Struct, _change_values: bool) -> bool:
	var size = current_pitch_state.all_physic_object_list.size()
	for object_2_index in range(size):
		var object_2 = current_pitch_state.all_physic_object_list[object_2_index]
		if object_1.index != object_2.index:
			if has_collision_physics_object(object_1, object_2, _change_values):
				return true
	return false

func has_collision_specific_Object_NoBall(object_1: PhysicObject_Struct, _change_values: bool) -> bool:
	var size = current_pitch_state.all_physic_object_list.size()
	for object_2_index in range(size):
		var object_2 = current_pitch_state.all_physic_object_list[object_2_index]
		if object_1.index != object_2.index and object_2.is_a_player:
			if has_collision_physics_object(object_1, object_2, _change_values):
				return true
	return false

#endregion



#region Physics Wall Collisions


func collision_wall_resolution() -> void:
	current_pitch_state.middle_x = Pitch_Middle_Point.global_position.x
	current_pitch_state.middle_y = Pitch_Middle_Point.global_position.y
	for object_A in current_pitch_state.all_physic_object_list:
		if has_collision_wall_lines(object_A):
			handle_walls_collision(object_A)

func has_collision_wall_lines(physic_object: PhysicObject_Struct) -> bool:
	if physic_object.last_position.x >= current_pitch_state.middle_x:
		if check_circle_lines_collision(physic_object.last_position, physic_object.radius, AwayGoalWall_Line_points):
			return true
	else:
		if check_circle_lines_collision(physic_object.last_position, physic_object.radius, HomeGoalWall_Line_points):
			return true
	
	if physic_object.last_position.y >= current_pitch_state.middle_y:
		if check_circle_lines_collision(physic_object.last_position, physic_object.radius, BotWall_Line_points):
			return true
	else:
		if check_circle_lines_collision(physic_object.last_position, physic_object.radius, TopWall_Line_points):
			return true
			
	return false

# if object has collided with a wall
# - corrects their position, so they don't stay inside a wall
# - Reflects the velocity vector
func handle_walls_collision(object_1: PhysicObject_Struct) -> void:
	# Push the object out of the wall
	object_1.last_position += wall_collision_normal * wall_collision_depth
	
	# Reflect the velocity vector
	object_1.current_velocity = object_1.current_velocity.bounce(wall_collision_normal)
	
	current_pitch_state.all_physic_object_list[object_1.index] = object_1

# Returns true if the circle intersects the line
func check_circle_lines_collision(circle_center: Vector2, circle_radius: float, list_line_points: PackedVector2Array) -> bool:
	var size = list_line_points.size()
	if size < 3:
		return false
	
	var radius_squared = circle_radius * circle_radius
	# Step 1: Check if the circle collides with any of the line's edges
	for i in range(size - 1):
		# Get a point from the line
		var current_point = list_line_points[i]
		
		# Get next point index, loop around to the first point if we are at the last index
		# Get the next point after current_point from the line
		var next_point_index = i + 1
		var next_point = list_line_points[next_point_index]
		
		# Find the closest point on this line segment to the circle's center
		#var closest_point = get_closest_point_on_line(circle_center, current_point, next_point)
		var ab = next_point - current_point
		var ap = circle_center - current_point
		var t = clamp(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		var closest_point = current_point + ab * t
		
		# Calculate distance from circle center to the closest point
		var distance_squared = circle_center.distance_squared_to(closest_point)

		if distance_squared <= radius_squared:
			var distance = sqrt(distance_squared)
			wall_collision_normal = (circle_center - closest_point).normalized()
			
			if wall_collision_normal == Vector2.ZERO:
				wall_collision_normal = (next_point - current_point).orthogonal().normalized()
				
			wall_collision_depth = circle_radius - distance
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

# Returns true if the circle intersects the polygon's boundary or interior
func check_circle_polygon_collision(circle_center: Vector2, circle_radius: float, list_polygons_points: PackedVector2Array) -> bool:
	var size = list_polygons_points.size()
	if size < 3:
		return false
	
	var radius_squared = circle_radius * circle_radius
	# Step 1: Check if the circle collides with any of the polygon's edges
	for i in range(size):
		# Get a point from the polygon
		var current_point = list_polygons_points[i]
		
		# Get next point index, loop around to the first point if we are at the last index
		# Get the next point after current_point from the polygon
		var next_point_index = (i + 1) % size
		var next_point = list_polygons_points[next_point_index]
		
		# Find the closest point on this line segment to the circle's center
		#var closest_point = get_closest_point_on_line(circle_center, current_point, next_point)
		var ab = next_point - current_point
		var ap = circle_center - current_point
		var t = clamp(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		var closest_point = current_point + ab * t

		# Calculate distance from circle center to the closest point
		var distance_squared = circle_center.distance_squared_to(closest_point)
		
		# If the distance is less than the radius, a collision has occurred
		if distance_squared <= radius_squared:
			wall_collision_normal = (circle_center - closest_point).normalized()
			
			if wall_collision_normal == Vector2.ZERO:
				wall_collision_normal = (next_point - current_point).orthogonal().normalized()
			
			wall_collision_depth = radius_squared - distance_squared
			return true
		
	# Step 2: interior check (handles when the circle is entirely inside the polygon)
	if Geometry2D.is_point_in_polygon(circle_center, list_polygons_points):
		print("Inside Polygon")
		return true
		
	return false
#endregion

#region Movement
var global_Collision_Check_count: int

func movement_update(_delta: float) -> void:
	var size = current_pitch_state.all_physic_object_list.size()
	for index in range(size):
		# chama função do object que atualiza sua Velocity
		var new_velocity = current_pitch_state.all_physic_object_list[index].current_velocity * current_pitch_state.all_physic_object_list[index].friction;
		var mag = new_velocity.length_squared()
		
		if mag < 400:
			current_pitch_state.all_physic_object_list[index].current_velocity = Vector2.ZERO
			current_pitch_state.all_physic_object_list[index].is_moving = false
		else:
			current_pitch_state.all_physic_object_list[index].current_velocity = new_velocity
			current_pitch_state.all_physic_object_list[index].is_moving = true
		
		if current_pitch_state.all_physic_object_list[index].is_moving:
			global_Collision_Check_count = 0
			
			# - Percorre o caminho que o objeto iria passar entre um frame e outro
			# - Caso tenha alguma colisão no meio do caminho, retorna a posição que a peça estava
			#var new_Pos = verify_collision_between_objects_on_movement_line_LinearSearch(current_pitch_state.all_physic_object_list[index], 10.0, _delta)
			var Velocity_length = current_pitch_state.all_physic_object_list[index].current_velocity.length_squared()
			var new_Pos = current_pitch_state.all_physic_object_list[index].last_position
			
			if Velocity_length >= 1000000:
				new_Pos = verify_collision_between_objects_on_movement_line_LinearSearch(current_pitch_state.all_physic_object_list[index], 10.0, _delta)
			elif Velocity_length >= 250000:
				new_Pos = verify_collision_between_objects_on_movement_line_LinearSearch(current_pitch_state.all_physic_object_list[index], 5.0, _delta)
			else:
				new_Pos = current_pitch_state.all_physic_object_list[index].last_position + (current_pitch_state.all_physic_object_list[index].current_velocity * _delta)
			
			# Atualiza a posição do objeto
			current_pitch_state.all_physic_object_list[index].last_position = new_Pos

# Faz verificações de colisões entre a posição atual do objeto e a sua próxima posição (posição depois de se mover no proximo frame)
# "subdivisionsNumber" é a quantidade de verifições
# Usa a lógica de uma busca linear
func verify_collision_between_objects_on_movement_line_LinearSearch(object_1: PhysicObject_Struct, subdivisionsNumber: float, _delta: float) -> Vector2:
	var inicial_Pos = object_1.last_position
	var final_Pos = object_1.last_position + (object_1.current_velocity * _delta)
	
	var distance_squared = inicial_Pos.distance_squared_to(final_Pos)
	var radius_squared = object_1.radius * object_1.radius
	
	# verifica se o movimento é menor que seu proprio raio
	# caso for, não é necessario fazer a verificação de colisão
	if distance_squared < radius_squared:
		return final_Pos

	var result_Pos = final_Pos
	var lerp_step = 1.0 / subdivisionsNumber

	for i in range(0.0, subdivisionsNumber + 1):
		var lerp_value = lerp_step * i
		var current_Pos = inicial_Pos.lerp(final_Pos, lerp_value)
		
		# posiciono o objeto na posição nova
		object_1.last_position = current_Pos
		global_Collision_Check_count += 1
		
		# Verifico se esta colidindo com outro objeto
		if has_collision_specific_Object(object_1, true) or has_collision_wall_lines(object_1): # Colidiu com algo
			result_Pos = current_Pos
			
			# retorno a posição da colisão
			return result_Pos
	
	object_1.last_position = inicial_Pos
	return result_Pos

# Verifica se existe algo no caminho, verificando colisões, "subdivisionsNumber" é a quantidade de passos/verificações no caminho
func verify_collisions_on_path_LinearSearch_NoBall(object: PhysicObject_Struct, subdivisionsNumber: float, target: Vector2) -> bool:
	var inicial_Pos = object.last_position
	var final_Pos = target
	
	var colidiu = false

	var lerp_step = 1.0 / subdivisionsNumber
	for i in range(0.0, subdivisionsNumber + 1):
		var lerp_value = lerp_step * i
		var current_pos = inicial_Pos.lerp(final_Pos, lerp_value)
		object.last_position = current_pos
		# Verifico se esta colidindo com outro objeto
		if has_collision_specific_Object_NoBall(object, false):
			colidiu = true
			break
		
		if has_collision_wall_lines(object):
			colidiu = true
			break
	
	object.last_position = inicial_Pos
	return colidiu
#endregion
