extends Node2D
class_name SimulationController

#@export var debug: bool
var sim_index: int
var player_object = preload("res://Componentes/Simulation_AI/Scenes/Player2D_Simulation.tscn")
var ball_object = preload("res://Componentes/Simulation_AI/Scenes/Ball2D_Simulation.tscn")

@export var rotation_steps: int

var good_plays: Array[Play]
var medium_plays: Array[Play]
var bad_plays: Array[Play]

var position_difference: Vector2

var thread: Thread

@export_group("Test Variables")
var PhysicsObjects_List: Array[PhysicsObject2D]
var PhysicsObjects_List_balls: Array[PhysicsObject2D]

@export var Goal_Home: Goal2D_Simulation
@export var Goal_Away: Goal2D_Simulation

@export var ball_entered_home_goal: bool
@export var ball_entered_away_goal: bool

@export var current_sequancial_shots_num: int
@export var last_play_teamSide: int

@export var run_num_max_steps: int

var current_pitch_state: PitchState

var plays_to_simulate: Array[Play]
var list_of_pitch_state_after_play_simulation: Array[PitchState]

@export var list_lines: Array[Line2D]
var list_lines_points_0: PackedVector2Array
var list_lines_points_1: PackedVector2Array
var list_lines_points_2: PackedVector2Array
var list_lines_points_3: PackedVector2Array

var list_walls_lines_points: Array[PackedVector2Array] = []

var wall_collision_normal: Vector2
var wall_collision_depth: float

var count_steps = 0

@export var home_goal_polygon: CollisionPolygon2D
@export var home_goal_near_1_polygon: CollisionPolygon2D
@export var home_goal_near_2_polygon: CollisionPolygon2D
var home_goal_top_position: Vector2
var home_goal_bottom_position: Vector2

@export var away_goal_polygon: CollisionPolygon2D
@export var away_goal_near_1_polygon: CollisionPolygon2D
@export var away_goal_near_2_polygon: CollisionPolygon2D
var away_goal_top_position: Vector2
var away_goal_bottom_position: Vector2

var list_of_plays_simulated: Array[Play]

var simulation_ready: bool = false
var show_play_simulation_result: bool

func _ready() -> void:
	thread = Thread.new()
	#mutex = Mutex.new()

#func _process(delta: float) -> void:
	#print("current_pitch_state.all_physic_object_list size = ", current_pitch_state.all_physic_object_list.size())

func _exit_tree() -> void:
	thread.wait_to_finish()

func update_visuals_position() -> void:
	for object in current_pitch_state.all_physic_object_list:
		PhysicsObjects_List[object.index].global_position = object.last_position - global_position


#region Start simulation
func update_pitch_state_variables(_pitch_state: PitchState) -> void:
	if current_pitch_state == null:
		current_pitch_state = PitchState.new()
	
	current_pitch_state.all_physic_object_list.clear()
	
	for i in _pitch_state.all_physic_object_list.size():
		var new_PhysicObject_Struct = PhysicObject_Struct.new()
		
		new_PhysicObject_Struct.index = _pitch_state.all_physic_object_list[i].index
		new_PhysicObject_Struct.last_position = _pitch_state.all_physic_object_list[i].last_position + global_position
		new_PhysicObject_Struct.current_velocity = _pitch_state.all_physic_object_list[i].current_velocity
		
		new_PhysicObject_Struct.mass = _pitch_state.all_physic_object_list[i].mass
		new_PhysicObject_Struct.friction = _pitch_state.all_physic_object_list[i].friction
		new_PhysicObject_Struct.scale = _pitch_state.all_physic_object_list[i].scale
		new_PhysicObject_Struct.radius = _pitch_state.all_physic_object_list[i].radius
		
		if _pitch_state.all_physic_object_list[i].is_a_player:
			new_PhysicObject_Struct.teamSide = _pitch_state.all_physic_object_list[i].teamSide
			new_PhysicObject_Struct.is_a_player = true
			new_PhysicObject_Struct.level_force = _pitch_state.all_physic_object_list[i].level_force
			new_PhysicObject_Struct.level_force_weak = _pitch_state.all_physic_object_list[i].level_force_weak
			new_PhysicObject_Struct.level_force_strong = _pitch_state.all_physic_object_list[i].level_force_strong
			new_PhysicObject_Struct.current_min_force = _pitch_state.all_physic_object_list[i].current_min_force
			new_PhysicObject_Struct.current_max_force = _pitch_state.all_physic_object_list[i].current_max_force
			
		else:
			new_PhysicObject_Struct.is_a_player = false
		
		new_PhysicObject_Struct.last_touch_index = _pitch_state.all_physic_object_list[i].last_touch_index
		new_PhysicObject_Struct.last_touch_position = _pitch_state.all_physic_object_list[i].last_touch_position
		
		current_pitch_state.all_physic_object_list.append(new_PhysicObject_Struct) 
	
	current_pitch_state.home_score = _pitch_state.home_score
	current_pitch_state.away_score = _pitch_state.away_score
	
	current_pitch_state.can_score_goal = _pitch_state.can_score_goal
	current_pitch_state.ball_possesion_counter = _pitch_state.ball_possesion_counter
	current_pitch_state.current_team_playing = _pitch_state.current_team_playing
	
	update_objects_positions()

func Set_Pitch_Simulation_Lines() -> void:
	# Physics Objects
	list_walls_lines_points.clear()
	list_lines_points_0.clear()
	list_lines_points_1.clear()
	list_lines_points_2.clear()
	list_lines_points_3.clear()
	
	for point in list_lines[0].points:
		list_lines_points_0.append(list_lines[0].to_global(point))

	for point in list_lines[1].points:
		list_lines_points_1.append(list_lines[1].to_global(point))

	for point in list_lines[2].points:
		list_lines_points_2.append(list_lines[2].to_global(point))

	for point in list_lines[3].points:
		list_lines_points_3.append(list_lines[3].to_global(point))
	
	list_walls_lines_points.append(list_lines_points_0)
	list_walls_lines_points.append(list_lines_points_1)
	list_walls_lines_points.append(list_lines_points_2)
	list_walls_lines_points.append(list_lines_points_3)
	
	home_goal_top_position = Goal_Home.Goal_top_position.global_position
	home_goal_bottom_position = Goal_Home.Goal_bottom_position.global_position
	
	away_goal_top_position = Goal_Away.Goal_top_position.global_position
	away_goal_bottom_position = Goal_Away.Goal_bottom_position.global_position
	#
	#print("Score for team Home = ", evaluate_pitch_state_based_on_team(current_pitch_state, 0))
	#print("Score for team Away = ", evaluate_pitch_state_based_on_team(current_pitch_state, 1))

func create_objects_copy(_show_play_simulation_result: bool) -> void:
	show_play_simulation_result = _show_play_simulation_result
	for object in current_pitch_state.all_physic_object_list:
		if object.is_a_player:
			var instance = player_object.instantiate()
			instance.global_position = object.last_position
			instance.index = object.index
			instance.name = "PLayer_" + str(object.index)
			
			if show_play_simulation_result:
				instance.visible = true
			else:
				instance.visible = false
			
			instance.scale = object.scale
			instance.mass = object.mass
			instance.friction = object.friction
			
			add_child(instance)
			PhysicsObjects_List.append(instance)
			
		else:
			var instance = ball_object.instantiate()
			instance.global_position = object.last_position
			instance.index = object.index
			
			instance.scale = object.scale
			instance.mass = object.mass
			instance.friction = object.friction
			
			if show_play_simulation_result:
				instance.visible = true
			else:
				instance.visible = false
			
			add_child(instance)
			PhysicsObjects_List.append(instance)
			PhysicsObjects_List_balls.append(instance)
#endregion

#region simulation
func Replicate_Action(index: int, velocity: Vector2, teamSide: int):
	count_steps = 0

	#Execute_Physic_Simulation_Run(0.016667, index, velocity, teamSide, true)
	# 1. Clean up the thread if it finished its previous run
	if thread.is_started() and not thread.is_alive():
		thread.wait_to_finish() # Joins and resets the thread safely
	
	# 2. Only start if it is completely inactive
	if not thread.is_alive():
		# Bind variables to your callable
		var task = Callable(self, "Execute_Physic_Simulation_Run").bind(0.016667, index, velocity, teamSide)
		
		# Start the thread execution
		thread.start(task)

func update_objects_positions() -> void:
	for i in current_pitch_state.all_physic_object_list.size():
		current_pitch_state.all_physic_object_list[i].last_position = current_pitch_state.all_physic_object_list[i].last_position

func Execute_Physic_Simulation_Run(_delta: float, play_index: int, play_velocity: Vector2, play_teamSide: int) -> int:
	current_pitch_state.all_physic_object_list[play_index].current_velocity = play_velocity
	
	var ball = null
	for piece in current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece
	
	current_pitch_state.last_ball = ball
	
	# Reset Variables
	current_pitch_state.score = 0
	for object in current_pitch_state.all_physic_object_list:
		object.last_touch_index = -1
		object.last_touch_position = Vector2.ZERO
		
	for i in range(current_pitch_state.all_physic_object_list.size()):
		current_pitch_state.all_physic_object_list[play_index].is_moving = false
	
	ball_entered_home_goal = false
	ball_entered_away_goal = false
	
	# garante que todos os objetos estão no lugar que deveriam e com as variaveis corretas
	update_objects_positions()

	var start_time_simulation = Time.get_ticks_usec()
	for i in range(run_num_max_steps + 1):
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
		
		# Check if ball entered the home goal area
		for object in current_pitch_state.all_physic_object_list:
			if not object.is_a_player:
				if check_circle_polygon_collision(object.last_position, object.radius, home_goal_polygon.polygon):
					ball_entered_home_goal = true
					break
				
				if check_circle_polygon_collision(object.last_position, object.radius, away_goal_polygon.polygon):
					ball_entered_away_goal = true
					break
		
		if ball_entered_home_goal or ball_entered_away_goal:
			print("Entered in a goal, finishes the simulation")
			break
		
		var all_stopped = true
		for j in range(current_pitch_state.all_physic_object_list.size()):
			if current_pitch_state.all_physic_object_list[j].is_moving == true:
				all_stopped = false
		
		if all_stopped == true:
			break
	
	var time_taken_simulation = (Time.get_ticks_usec() - start_time_simulation) / 1000000.0
	#print("Simulation took: ", time_taken_simulation, " seconds")
	
	if show_play_simulation_result:
		call_deferred("update_visuals_position")
		return 0
	else:
		current_pitch_state.score = evaluate_pitch_state_based_on_team(current_pitch_state, current_pitch_state.current_team_playing)
		return current_pitch_state.score

var simulation_ended: bool = false
var simulation_data_collected: bool = false

func Simulate_and_Evaluate_a_List_of_Plays(plays: Array[Play]) -> void:
	#print("plays size = ", plays.size())
	
	var start_time = Time.get_ticks_usec()
	for play in plays:
		play.score = Execute_Physic_Simulation_Run(0.016667, play.player_index, play.velocity, play.play_teamSide)
		list_of_plays_simulated.append(play)
	
	var time_taken = (Time.get_ticks_usec() - start_time) / 1000000.0
	print("Simulate_and_Evaluate_a_List_of_Plays ", sim_index, " took: ", time_taken, " seconds")
	
	simulation_ended = true
	simulation_data_collected = false


func Simulate_and_Evaluate_Thread_Execution(plays: Array[Play]) -> void:
	list_of_plays_simulated.clear()
	simulation_ended = false
	
	# 1. Clean up the thread if it finished its previous run
	if thread.is_started() and not thread.is_alive():
		thread.wait_to_finish() # Joins and resets the thread safely
	
	# 2. Only start if it is completely inactive
	if not thread.is_alive():
		# Bind variables to your callable
		var task = Callable(self, "Simulate_and_Evaluate_a_List_of_Plays").bind(plays)
		
		# Start the thread execution
		thread.start(task)
	
#endregion

#region Physics

#region Physics Objects Collisions
func collision_physics_object_resolution() -> void:
	for object_A_index in range(current_pitch_state.all_physic_object_list.size()):
		var object_A = current_pitch_state.all_physic_object_list[object_A_index]
		for object_B_index in range(object_A_index + 1, current_pitch_state.all_physic_object_list.size()):
			var object_B = current_pitch_state.all_physic_object_list[object_B_index]
			if has_collision_physics_object(object_A, object_B, true):
				handle_physics_objects_collision(object_A, object_B)

func has_collision_physics_object(object_1: PhysicObject_Struct, object_2: PhysicObject_Struct, change_values: bool) -> bool:
	var line_of_impact = object_2.last_position - object_1.last_position
	var distance = line_of_impact.length()
	
	var overlap = distance - (object_1.radius + object_2.radius)
	
	if overlap <= 0:
		if change_values:
			object_1.last_touch_index = object_2.index
			object_1.last_touch_position = object_1.last_position + line_of_impact.normalized() * object_1.radius
			
			object_2.last_touch_index = object_1.index
			object_2.last_touch_position = object_1.last_position + line_of_impact.normalized() * object_1.radius
		return true
	else:
		return false

func has_collision_specific_Object(object_1: PhysicObject_Struct, _change_values: bool) -> bool:
	for object_2_index in range(current_pitch_state.all_physic_object_list.size()):
		var object_2 = current_pitch_state.all_physic_object_list[object_2_index]
		if object_1.index != object_2.index:
			if has_collision_physics_object(object_1, object_2, _change_values):
				return true
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

#endregion

#region Physics Wall Collisions
func collision_wall_resolution() -> void:
	for i in range(current_pitch_state.all_physic_object_list.size()):
		var object_A = current_pitch_state.all_physic_object_list[i]
		if has_collision_wall_lines(object_A):
			handle_walls_collision(object_A)

func has_collision_wall_lines(physic_object: PhysicObject_Struct) -> bool:
	for line in list_walls_lines_points:
		if check_circle_lines_collision(physic_object.last_position, physic_object.radius, line):
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
	if list_line_points.size() < 3:
		return false
	
	# Step 1: Check if the circle collides with any of the line's edges
	for i in range(list_line_points.size() - 1):
		# Get a point from the line
		var current_point = list_line_points[i]
		
		# Get next point index, loop around to the first point if we are at the last index
		# Get the next point after current_point from the line
		var next_point_index = i + 1
		var next_point = list_line_points[next_point_index]
		
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
#endregion

#region Movement
var global_Collision_Check_count: int

func movement_update(_delta: float) -> void:
	for index in range(current_pitch_state.all_physic_object_list.size()):
		# chama função do object que atualiza sua Velocity
		var new_velocity = current_pitch_state.all_physic_object_list[index].current_velocity * current_pitch_state.all_physic_object_list[index].friction;
		
		var mag = new_velocity.length()
		
		if mag < 20:
			current_pitch_state.all_physic_object_list[index].current_velocity = Vector2.ZERO
			current_pitch_state.all_physic_object_list[index].is_moving = false
		else:
			current_pitch_state.all_physic_object_list[index].current_velocity = new_velocity
			current_pitch_state.all_physic_object_list[index].is_moving = true
		
		if current_pitch_state.all_physic_object_list[index].is_moving:
			global_Collision_Check_count = 0
			
			# - Percorre o caminho que o objeto iria passar entre um frame e outro
			# - Caso tenha alguma colisão no meio do caminho, retorna a posição que a peça estava
			var new_Pos = verify_collision_between_objects_on_movement_line_LinearSearch(current_pitch_state.all_physic_object_list[index], 10.0, _delta)
			
			# Atualiza a posição do objeto
			current_pitch_state.all_physic_object_list[index].last_position = new_Pos

# Faz verificações de colisões entre a posição atual do objeto e a sua próxima posição (posição depois de se mover no proximo frame)
# "subdivisionsNumber" é a quantidade de verifições
# Usa a lógica de uma busca linear
func verify_collision_between_objects_on_movement_line_LinearSearch(object_1: PhysicObject_Struct, subdivisionsNumber: float, _delta: float) -> Vector2:
	var inicial_Pos = object_1.last_position
	var final_Pos = object_1.last_position + (object_1.current_velocity * _delta)
	
	# verifica se o movimento é menor que seu proprio raio
	# caso for, não é necessario fazer a verificação de colisão
	if inicial_Pos.distance_to(final_Pos) < object_1.radius:
		return final_Pos

	var result_Pos = final_Pos
	var lerp_step = 1.0 / subdivisionsNumber
	
	#print("verify_collision_between_objects_on_movement_line_LinearSearch")
	
	for i in range(0.0, subdivisionsNumber + 1):
		#print("i = ", i)
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
#endregion

#endregion

#region Pitch Evaluation
func evaluate_pitch_state_based_on_team(_current_pitch_state: PitchState, _team: int) -> int:
	var score = 0
	
	#var start_time_evaluation = Time.get_ticks_usec()
	score += evaluate_pitch_state_Goal(_current_pitch_state, _team)
	if score >= 10000 or score <= -10000:
		return score
	
	score += evaluate_pitch_state_ball_possession(_current_pitch_state, _team)
	score += evaluate_pitch_state_ball_field_advance(_current_pitch_state, _team)
	score += evaluate_pitch_state_pieces_close_to_ball(_current_pitch_state, _team, 200)
	score += evaluate_pitch_state_defence(_current_pitch_state, _team, 500)
	score += evaluate_pitch_state_attack(_current_pitch_state, _team, 500)
	score += evaluate_pitch_state_Ball_close_to_goal(_current_pitch_state, _team)
	
	#var time_taken_evaluation = (Time.get_ticks_usec() - start_time_evaluation) / 1000000.0
	#print("Evaluation took: ", time_taken_evaluation, " seconds")
	
	return score

# Goal Evaluation
func evaluate_pitch_state_Goal(_current_pitch_state: PitchState, _team: int) -> int:
	var score = 0
	if ball_entered_home_goal:
		#print("ball_entered_home_goal _team = ", _team)
		print("ball_entered_home_goal")
		if _team == 0:
			score += -10000
		else:
			score += 10000
		
	if ball_entered_away_goal:
		#print("ball_entered_away_goal _team = ", _team)
		print("ball_entered_away_goal")
		if _team == 1:
			score += -10000
		else:
			score += 10000
	
	#print("Goal Added = ", score)
	return score

# Evaluation about maintaining the ball possession
func evaluate_pitch_state_ball_possession(_current_pitch_state: PitchState, _team: int) -> int:
	var score = 0
	
	if will_maintain_ball_possession(_current_pitch_state, _team):
		score += 400
	else:
		score -= 200
	
	print("ball_possession Added = ", score)
	return score

# Evaluation of how much the ball advanced on the field in direction of the goal
func evaluate_pitch_state_ball_field_advance(_current_pitch_state: PitchState, _team: int) -> int:
	var score = 0
	
	var ball = null
	for piece in _current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece
		
	if ball != null and _current_pitch_state.last_ball != null:
		if _team == 0:
			var goal_pos = away_goal_top_position.lerp(away_goal_bottom_position, 0.5)
			var dist_ball_to_goal = (ball.last_position - goal_pos).length()
			var dist_last_ball_to_goal = (_current_pitch_state.last_ball.last_position - goal_pos).length()
			
			var dist_dif = dist_ball_to_goal - dist_last_ball_to_goal
			score += 0.5 * dist_dif
		elif _team == 1:
			var goal_pos = home_goal_top_position.lerp(home_goal_bottom_position, 0.5)
			var dist_ball_to_goal = (ball.last_position - goal_pos).length()
			var dist_last_ball_to_goal = (_current_pitch_state.last_ball.last_position - goal_pos).length()
			
			var dist_dif = dist_ball_to_goal - dist_last_ball_to_goal
			score += 0.5 * dist_dif
	else:
		print("Erro: pitch state não contem um objeto bola (evaluate_pitch_state_ball_field_advance)")
	
	#print("ball_field_advance Added = ", score)
	return score

# Evaluation of how many ally pieces are close to the ball
func evaluate_pitch_state_pieces_close_to_ball(_current_pitch_state: PitchState, _team: int, max_dist: int) -> int:
	var score = 0

	# get ball piece
	var ball = null
	for piece in _current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece
	
	var num_pieces_from_team_close_to_ball = 0
	#var num_pieces_from_team_enemy_to_ball = 0
	if ball != null:
		for piece in _current_pitch_state.all_physic_object_list:
			if piece.is_a_player and piece.teamSide == _team:
				var dist = piece.last_position.distance_to(ball.last_position)
				if dist <= max_dist:
					num_pieces_from_team_close_to_ball += 1
	else:
		print("Erro: pitch state não contem um objeto bola (evaluate_pitch_state_pieces_close_to_ball)")
	
	# Aumenta a pontuação dependendo de quantas peças do time estão proximas da bola
	if num_pieces_from_team_close_to_ball > 0:
		score += 30 * num_pieces_from_team_close_to_ball
	# Diminui a pontuação se nenhuma peça do time esta perto da bola
	elif num_pieces_from_team_close_to_ball <= 0:
		score -= 100
	
	#print("pieces_close_to_ball Added = ", score)
	return score

# Evaluation if ally goal is defended, verifying if there is any piece on the way of the ball to the ally goal
func evaluate_pitch_state_defence(_current_pitch_state: PitchState, _team: int, max_dist: int) -> int:
	var score = 0
	var goal_lerp_steps = 3
	
	var ball = null
	for piece in _current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece
	
	if ball != null:
		var path_defended = 0
		if _team == 0:
			var goal_pos = home_goal_top_position.lerp(home_goal_bottom_position, 0.5)
			var dist = (goal_pos - ball.last_position).length()
			if dist < max_dist:
				for i in range(goal_lerp_steps):
					var lerp_pos = i / (goal_lerp_steps - 1.0)
					var new_goal_pos = home_goal_top_position.lerp(home_goal_bottom_position, lerp_pos)
					if verify_collisions_on_path_LinearSearch(ball, 5, new_goal_pos):
						path_defended += 1
			else:
				path_defended += 5
		elif _team == 1:
			var goal_pos = away_goal_top_position.lerp(away_goal_bottom_position, 0.5)
			var dist = (goal_pos - ball.last_position).length()
			if dist < max_dist:
				for i in range(goal_lerp_steps):
					var lerp_pos = i / (goal_lerp_steps - 1.0)
					var new_goal_pos = away_goal_top_position.lerp(away_goal_bottom_position, lerp_pos)
					if verify_collisions_on_path_LinearSearch(ball, 5, new_goal_pos):
						path_defended += 1
			else:
				path_defended += 5
			
		# Aumenta a pontuação para cada caminho que a bola não tem o caminho livre até o gol aliado
		if path_defended > 0:
			score += 20 * path_defended
		# Diminui a pontuação se a bola tem o caminho livre até o gol aliado
		elif path_defended <= 0:
			score -= 100
	else:
		print("Erro: pitch state não contem um objeto bola (evaluate_pitch_state_defence)")
	
	#print("defence Added = ", score)
	return score

# Evaluation if there is a free way to attack enemy goal, verifying if there is any piece on the way of the ball to the enemy goal
func evaluate_pitch_state_attack(_current_pitch_state: PitchState, _team: int, max_dist: int) -> int:
	var score = 0
	var goal_lerp_steps = 3
	
	var ball = null
	for piece in _current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece
	
	if ball != null:
		var path_free = 0
		if _team == 0:
			var goal_pos = away_goal_top_position.lerp(away_goal_bottom_position, 0.5)
			var dist = (goal_pos - ball.last_position).length()
			if dist < max_dist:
				for i in range(goal_lerp_steps):
					var lerp_pos = i / (goal_lerp_steps - 1.0)
					var new_goal_pos = away_goal_top_position.lerp(away_goal_bottom_position, lerp_pos)
					if not verify_collisions_on_path_LinearSearch(ball, 5, new_goal_pos):
						path_free += 1
			
		elif _team == 1:
			var goal_pos = home_goal_top_position.lerp(home_goal_bottom_position, 0.5)
			var dist = (goal_pos - ball.last_position).length()
			if dist < max_dist:
				for i in range(goal_lerp_steps):
					var lerp_pos = i / (goal_lerp_steps - 1.0)
					var new_goal_pos = home_goal_top_position.lerp(home_goal_bottom_position, lerp_pos)
					
					if not verify_collisions_on_path_LinearSearch(ball, 5, new_goal_pos):
						path_free += 1
		
		# Aumenta a pontuação se a bola tem o caminho livre até o gol
		if path_free > 0:
			score += 150 * path_free
		# Diminui a pontuação se a bola não tem nenhum caminho livre até o gol
		elif path_free <= 0:
			score -= 200
	else:
		print("Erro: pitch state não contem um objeto bola (evaluate_pitch_state_attack)")
	
	#print("attack Added = ", score)
	return score

# Evaluating the distance of the ball towards the goals
func evaluate_pitch_state_Ball_close_to_goal(_current_pitch_state: PitchState, _team: int) -> int:
	var score = 0

	# get ball piece
	var ball = null
	for piece in _current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece
	
	var dist_from_home_goal = 0
	var dist_from_away_goal = 0
	
	if ball != null:
		dist_from_home_goal = ball.last_position.distance_to(home_goal_top_position.lerp(home_goal_bottom_position, 0.5))
		dist_from_away_goal = ball.last_position.distance_to(away_goal_top_position.lerp(away_goal_bottom_position, 0.5))
	else:
		print("Erro: pitch state não contem um objeto bola (evaluate_pitch_state_pieces_close_to_ball)")
	
	# Aumenta a pontuação se a bola estiver mais perto do gol do time inimigo
	if _team == 0:
		var score_dist_from_home_goal = dist_from_home_goal * 0.1
		var score_dist_from_away_goal = dist_from_away_goal * -0.1
		
		score = score_dist_from_home_goal + score_dist_from_away_goal
		
	elif _team == 1:
		var score_dist_from_home_goal = dist_from_home_goal * -0.1
		var score_dist_from_away_goal = dist_from_away_goal * 0.1
		
		score = score_dist_from_home_goal + score_dist_from_away_goal
	
	print("Ball_close_to_goal Added = ", score)
	return score

#endregion

#region Pitch Evaluation Utils
func will_maintain_ball_possession(_current_pitch_state: PitchState, _team: int) -> bool:
	var ball = null
	for piece in _current_pitch_state.all_physic_object_list:
		if !piece.is_a_player:
			ball = piece

	if ball != null:
		if _current_pitch_state.ball_possesion_counter < 2 and ball.last_touch_index != -1:
			if _current_pitch_state.all_physic_object_list[ball.last_touch_index].teamSide == _team:
				return true
			else:
				return false
		else:
			return false
	else:
		print("Erro: pitch state não contem um objeto bola (ball_possession function)")
		return false

# Verifica se existe algo no caminho, verificando colisões, "subdivisionsNumber" é a quantidade de passos/verificações no caminho
func verify_collisions_on_path_LinearSearch(object: PhysicObject_Struct, subdivisionsNumber: float, target: Vector2) -> bool:
	var inicial_Pos = object.last_position
	var final_Pos = target
	
	var colidiu = false

	var lerp_step = 1.0 / subdivisionsNumber
	for i in range(0.0, subdivisionsNumber + 1):
		var lerp_value = lerp_step * i
		var current_pos = inicial_Pos.lerp(final_Pos, lerp_value)
		object.last_position = current_pos
		# Verifico se esta colidindo com outro objeto
		if has_collision_specific_Object(object, false):
			colidiu = true
			break
		
		if has_collision_wall_lines(object):
			colidiu = true
			break
	
	object.last_position = inicial_Pos
	return colidiu
#endregion
