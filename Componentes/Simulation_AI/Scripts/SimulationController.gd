extends Node2D
class_name SimulationController

@export var debug: bool

var player_object = preload("res://Componentes/Simulation_AI/Scenes/Player2D_Simulation.tscn")
var ball_object = preload("res://Componentes/Simulation_AI/Scenes/Ball2D_Simulation.tscn")

@export var run_num_max_steps: int
@export var max_force_steps: int

#var object_A: PhysicObject_Struct
#var object_B: PhysicObject_Struct

@export var rotation_steps: int

var good_plays: Array[Play]
var medium_plays: Array[Play]
var bad_plays: Array[Play]

var position_difference: Vector2

var thread: Thread
#var mutex: Mutex

@export_group("Test Variables")
var PhysicsObjects_List: Array[PhysicsObject2D]
var PhysicsObjects_List_balls: Array[PhysicsObject2D]

@export var Goal_Home: Goal2D_Simulation
@export var Goal_Away: Goal2D_Simulation

@export var ball_entered_goal: bool
@export var ball_entered_enemy_goal: bool

@export var current_sequancial_shots_num: int
@export var last_play_teamSide: int

var current_pitch_state: PitchState

@export var list_walls_polygons: Array[CollisionPolygon2D]
var list_walls_polygons_points_0: Array[Vector2]
var list_walls_polygons_points_1: Array[Vector2]
var list_walls_polygons_points_2: Array[Vector2]
var list_walls_polygons_points_3: Array[Vector2]


var wall_collision_normal: Vector2
var wall_collision_depth: float

func _ready() -> void:
	current_pitch_state = PitchState.new()
	thread = Thread.new()
	#mutex = Mutex.new()
	

	for point in list_walls_polygons[0].polygon:
		list_walls_polygons_points_0.append(list_walls_polygons[0].to_global(point))

	for point in list_walls_polygons[1].polygon:
		list_walls_polygons_points_1.append(list_walls_polygons[1].to_global(point))

	for point in list_walls_polygons[2].polygon:
		list_walls_polygons_points_2.append(list_walls_polygons[2].to_global(point))

	for point in list_walls_polygons[3].polygon:
		list_walls_polygons_points_3.append(list_walls_polygons[3].to_global(point))



func _exit_tree() -> void:
	thread.wait_to_finish()


func update_visuals_position() -> void:
	#print("simulation --------------------------------")
	for object in current_pitch_state.all_physic_object_list:
		PhysicsObjects_List[object.index].global_position = object.last_position
		
		#print("global_position = ", PhysicsObjects_List[object.index].global_position)
		#
		#print("index = ", object.index)
		#print("last_position = ", object.last_position)

#region simulation
func copy_pitch_state_variables(_pitch_state: PitchState) -> void:
	current_pitch_state = _pitch_state

func create_objects_copy(_debug: bool) -> void:
	debug = _debug
	for object in current_pitch_state.all_physic_object_list:
		if object.is_a_player:
			var instance = player_object.instantiate()
			instance.global_position = object.last_position
			instance.index = object.index
			instance.name = "PLayer_" + str(object.index)
			
			if debug:
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
			
			add_child(instance)
			PhysicsObjects_List.append(instance)
			PhysicsObjects_List_balls.append(instance)

func update_objects_positions_and_variables(initial_position: Vector2) -> void:
	position_difference = global_position - initial_position

	for i in current_pitch_state.all_physic_object_list.size():
		#mutex.lock()
		current_pitch_state.all_physic_object_list[i].last_position = current_pitch_state.all_physic_object_list[i].last_position + position_difference
		#mutex.unlock()

func Replicate_Action(index: int, velocity: Vector2, teamSide: int):
	count_steps = 0
	
	#update_visuals_position()
	
	#thread.start(Execute_Physic_Simulation_Run.bind(0.016667, index, velocity, teamSide))
	#Execute_Physic_Simulation_Run(0.016667, index, velocity, teamSide)
	
	
	
	print("Is thread alive = ", thread.is_alive())
	
	# 1. Clean up the thread if it finished its previous run
	if thread.is_started() and not thread.is_alive():
		print("wait_to_finish")
		thread.wait_to_finish() # Joins and resets the thread safely
	
	# 2. Only start if it is completely inactive
	if not thread.is_alive():
		print("THREADS - Execute_Physic_Simulation_Run")
		# Bind variables to your callable
		var task = Callable(self, "Execute_Physic_Simulation_Run").bind(0.016667, index, velocity, teamSide)
		
		# Start the thread execution
		thread.start(task)
	else:
		print("Thread is still running! Wait for it.")
	


var count_steps = 0

func Execute_Physic_Simulation_Run(_delta: float, play_index: int, play_velocity: Vector2, play_teamSide: int) -> void:
	print("THREADS - play_index = ", play_index)
	print("THREADS - play_velocity = ", play_velocity)
	print("THREADS - play_teamSide = ", play_teamSide)
	current_pitch_state.all_physic_object_list[play_index].current_velocity = play_velocity
	
	# garante que todos os objetos estão no lugar que deveriam e com as variaveis corretas
	update_objects_positions_and_variables(global_position)
	
	for i in range(current_pitch_state.all_physic_object_list.size()):
		current_pitch_state.all_physic_object_list[play_index].is_moving = false
	
	ball_entered_goal = false
	ball_entered_enemy_goal = false
	
	#for polygon in list_walls_polygons:
		#print("simulation polygon point ----------------------------")
		#print(polygon.polygon)
	
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

		#if current_pitch_state.all_physic_object_list[0].is_moving:
			#print("Simulation step = ", count_steps)
			#print("Simulation current_velocity = ", current_pitch_state.all_physic_object_list[0].current_velocity)
			#print("Simulation last_position = ", current_pitch_state.all_physic_object_list[0].last_position)
		
		count_steps += 1
		#print("i = ", i)

		#for object in current_pitch_state.all_physic_object_list:
			#if object.is_in_group("Balls"):
				#object.shapecast_goals.force_shapecast_update()
				#if object.shapecast_goals.is_colliding():
					#var collider = object.shapecast_goals.get_collider(0)
					#var collider_parent_node = collider.get_parent()
					#
					#if collider_parent_node.team == play_teamSide:
						#ball_entered_goal = true
						#break
					#else:
						#ball_entered_enemy_goal = true
						#break
		
		var all_stopped = true
		for j in range(current_pitch_state.all_physic_object_list.size()):
			if current_pitch_state.all_physic_object_list[j].is_moving == true:
				all_stopped = false
		
		if all_stopped == true:
			break
	
	call_deferred("update_visuals_position")

#endregion

#region Physics
#region Physics Objects Collisions
func collision_physics_object_resolution() -> void:
	for object_A_index in range(current_pitch_state.all_physic_object_list.size()):
		var object_A = current_pitch_state.all_physic_object_list[object_A_index]
		for object_B_index in range(object_A_index + 1, current_pitch_state.all_physic_object_list.size()):
			var object_B = current_pitch_state.all_physic_object_list[object_B_index]
			if has_collision_physics_object(object_A, object_B):
				handle_physics_objects_collision(object_A, object_B)

func has_collision_physics_object(object_1: PhysicObject_Struct, object_2: PhysicObject_Struct) -> bool:
	var line_of_impact = object_2.last_position - object_1.last_position
	var distance = line_of_impact.length()
	
	var overlap = distance - (object_1.radius + object_2.radius)
	#print("Overlap = ", overlap)
	
	if overlap <= 0:
		object_1.last_touch_index = object_2.index
		object_1.last_touch_position = object_1.last_position + line_of_impact.normalized() * object_1.radius
		
		#print("object_1.last_touch_position 1 = ", current_pitch_state.all_physic_object_list[object_1.index].last_touch_position)
		current_pitch_state.all_physic_object_list[object_1.index] = object_1
		#print("object_1.last_touch_position 2 = ", current_pitch_state.all_physic_object_list[object_1.index].last_touch_position)

		object_2.last_touch_index = object_1.index
		object_2.last_touch_position = object_1.last_position + line_of_impact.normalized() * object_1.radius
		
		current_pitch_state.all_physic_object_list[object_2.index] = object_2
		return true
	else:
		return false

func has_collision_specific_Object(object_1: PhysicObject_Struct) -> bool:
	for index in range(current_pitch_state.all_physic_object_list.size()):
		var object_2 = current_pitch_state.all_physic_object_list[index]
		if object_1.index != object_2.index:
			if has_collision_physics_object(object_1, object_2):
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
	
	#mutex.lock()
	object_1.last_position = object_1.last_position + ((-line_of_impact * (overlap * 0.51)))
	object_2.last_position = object_2.last_position + ((line_of_impact * (overlap * 0.51)))
	#mutex.unlock()
	
	current_pitch_state.all_physic_object_list[object_1.index] = object_1
	current_pitch_state.all_physic_object_list[object_2.index] = object_2

#endregion

#region Physics Wall Collisions

func collision_wall_resolution() -> void:
	for i in range(current_pitch_state.all_physic_object_list.size()):
		var object_A = current_pitch_state.all_physic_object_list[i]
		if has_collision_wall_polygons(object_A):
			handle_walls_collision(object_A)

func has_collision_wall_polygons(physic_object: PhysicObject_Struct) -> bool:
	for index in list_walls_polygons.size():
		if physic_object.is_moving:
			if index == 0:
				if check_circle_polygon_collision(physic_object.last_position, physic_object.radius, list_walls_polygons_points_0):
					print("simulation - Colidded with wall index = ", index)
					return true
			elif index == 1:
				if check_circle_polygon_collision(physic_object.last_position, physic_object.radius, list_walls_polygons_points_1):
					print("simulation - Colidded with wall index = ", index)
					return true
			elif index == 2:
				if check_circle_polygon_collision(physic_object.last_position, physic_object.radius, list_walls_polygons_points_2):
					print("simulation - Colidded with wall index = ", index)
					return true
			elif index == 3:
				if check_circle_polygon_collision(physic_object.last_position, physic_object.radius, list_walls_polygons_points_3):
					print("simulation - Colidded with wall index = ", index)
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


# Returns true if the circle intersects the polygon's boundary or interior
func check_circle_polygon_collision(circle_center: Vector2, circle_radius: float, list_polygons_points: Array[Vector2]) -> bool:
	if list_polygons_points.size() < 3:
		return false
		
	# Step 1: Check if the circle collides with any of the polygon's edges
	for i in range(list_polygons_points.size()):
		# Get a point from the polygon
		var current_point = list_polygons_points[i]
		
		# Get next point index, loop around to the first point if we are at the last index
		var next_point_index = (i + 1) % list_polygons_points.size()
		
		# Get the next point after current_point from the polygon
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
			#print("Colidiu com a parede")
			#print("circle_radius = ", circle_radius)
			
			return true
			
	## Step 2: interior check (handles when the circle is entirely inside the polygon)
	#if Geometry2D.is_point_in_polygon(circle_center, CollisionPolygon.polygon):
		##print("Inside Wall")
		#return true
		
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
	for index in range(current_pitch_state.all_physic_object_list.size()):
		# chama função do object que atualiza sua Velocity
		var new_velocity = current_pitch_state.all_physic_object_list[index].current_velocity * current_pitch_state.all_physic_object_list[index].friction;
		
		var vel_x = abs(current_pitch_state.all_physic_object_list[index].current_velocity.x)
		var vel_y = abs(current_pitch_state.all_physic_object_list[index].current_velocity.y)
		
		if vel_x < 10 && vel_y < 10:
			current_pitch_state.all_physic_object_list[index].current_velocity = Vector2.ZERO
			current_pitch_state.all_physic_object_list[index].is_moving = false
		else:
			current_pitch_state.all_physic_object_list[index].current_velocity = new_velocity
			current_pitch_state.all_physic_object_list[index].is_moving = true
		
		
		
		if current_pitch_state.all_physic_object_list[index].is_moving:
			global_Collision_Check_count = 0
			# Acha a proxima posição do objeto
			# - Percorre o caminho que o objeto iria passar entre um frame e outro
			# - Caso tenha alguma colisão no meio do caminho, retorna a posição dessa colisão
			var new_Pos = verify_collision_between_objects_on_movement_line_LinearSearch(current_pitch_state.all_physic_object_list[index], 10.0, _delta)
			
			# Atualiza a posição do objeto
			#mutex.lock()
			current_pitch_state.all_physic_object_list[index].last_position = new_Pos
			#mutex.unlock()




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

	for i in range(0.0, subdivisionsNumber + 1):
		var lerp_value = lerp_step * i
		var current_Pos = inicial_Pos.lerp(final_Pos, lerp_value)

		# posiciono o objeto na posição nova
		#mutex.lock()
		object_1.last_position = current_Pos
		#mutex.unlock()

		global_Collision_Check_count += 1
		
		# Verifico se esta colidindo com outro objeto
		if has_collision_specific_Object(object_1) or has_collision_wall_polygons(object_1): # Colidiu com algo
			result_Pos = current_Pos
			#print("LinearSearch - Colidiu com algo")
			# retorno a posição da colisão
			return result_Pos

	#mutex.lock()
	object_1.last_position = inicial_Pos
	#mutex.unlock()
	
	return result_Pos

# Faz verificações de colisões entre a posição atual do objeto e a sua próxima posição (posição depois de se mover no proximo frame)
# "subdivisionsNumber" é a quantidade de verifições
# Usa a lógica de uma busca binária
#func verify_collision_between_objects_on_movement_line_BooleanSearch(object_1: PhysicsObject2D, subdivisionsNumber: float, _delta: float) -> Vector2:
	#var inicial_Pos = object_1.global_position
	#var final_Pos = object_1.global_position + (object_1.current_velocity * _delta)
	#
	#var result_Pos = final_Pos
	#
	##print("Start --------------")
	##print("final_Pos = ", final_Pos)
	#
	#var circle_shape_object_1: CircleShape2D = object_1.shapecast_physics_objects.shape as CircleShape2D
	#var radius_object_1: float = circle_shape_object_1.radius
	#
	#if inicial_Pos.distance_to(final_Pos) < radius_object_1:
		##print("Distance Too Small")
		#return final_Pos
	#
	## verifico se aconteceu alguma colisão na posição final
	#object_1.global_position = final_Pos
	#object_1.shapecast_physics_objects.force_shapecast_update()
	#object_1.shapecast_walls.force_shapecast_update()
#
	#global_Collision_Check_count += 1
	#
	## posição final esta colidindo com outro objeto, então verificar posições anteriores para pegar a posição mais precisa da colisão
	#if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): 
		#result_Pos = object_1.global_position
		##print("final position has collision")
	## posição final não colidiu com nada, então verificar posições anteriores
	#else:
		##print("final position has NO collision")
		#result_Pos = verify_collision_between_objects_on_movement_line_recursive(object_1, subdivisionsNumber, inicial_Pos, final_Pos)
	#
	## colidiu com algo
	#if result_Pos != Vector2.ZERO: 
		## tenta achar a posição mais próxima do objeto mas que continue tendo colisão
		#return result_Pos #= #verify_collision_between_objects_on_movement_line_after_collision_found(object_1, subdivisionsNumber, result_Pos)
	## Não colidiu com nada, retorna a posição final do movimento
	#else:
		#result_Pos = final_Pos
	#
	#object_1.global_position = inicial_Pos
	#
	#return result_Pos
#
#func verify_collision_between_objects_on_movement_line_recursive(object_1: PhysicsObject2D, subdivisionsNumber: float, inicial_Pos: Vector2, final_Pos: Vector2) -> Vector2:
	#var current_Pos = inicial_Pos.lerp(final_Pos, 0.5)
	#var result_Pos = Vector2.ZERO
	##print("------------------------------------------")
	##print("subdivisionsNumber = ", subdivisionsNumber)
	##print("current_Pos = ", current_Pos)
	## posiciono o objeto na posição nova
	#object_1.global_position = current_Pos
	#
	## atualizo as informações do shapecast
	#object_1.shapecast_physics_objects.force_shapecast_update()
	#object_1.shapecast_walls.force_shapecast_update()
	#
	#global_Collision_Check_count += 1
	#
	## Verifico se esta colidindo com outro objeto
	#if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): # Colidiu com algo
		#result_Pos = current_Pos
		#
		## retorno a posição da colisão
		#return result_Pos
	#else: # Nao Colidiu
		## diminuo a quantidade de subdivisões para serem feites
		#subdivisionsNumber -= 1
		#
		## verifico se ainda pode procurar mais
		#if subdivisionsNumber > 0:
			#var pos_1 = Vector2.ZERO
			#var pos_2 = Vector2.ZERO
			#
			## defino as variaveis para procurar na metade anterior ao meio (inicio -> meio)
			#var new_inicial_Pos = inicial_Pos
			#var new_final_Pos = current_Pos
			#
			#var circle_shape_object_1: CircleShape2D = object_1.shapecast_physics_objects.shape as CircleShape2D
			#var radius_object_1: float = circle_shape_object_1.radius
			#
			#if new_inicial_Pos.distance_to(new_final_Pos) > radius_object_1:
				#pos_1 = verify_collision_between_objects_on_movement_line_recursive(object_1, subdivisionsNumber, new_inicial_Pos, new_final_Pos)
			#
			## defino as variaveis para procurar na metade posterior ao meio (meio -> final)
			#new_inicial_Pos = current_Pos
			#new_final_Pos = final_Pos
			#
			#if new_inicial_Pos.distance_to(new_final_Pos) > radius_object_1:
				#pos_2 = verify_collision_between_objects_on_movement_line_recursive(object_1, subdivisionsNumber, new_inicial_Pos, new_final_Pos)
			#
			## Verifico se alguma retornou colisão (retornou um Vector2 diferente de 0)
			#if pos_1 != Vector2.ZERO and pos_2 != Vector2.ZERO:
				## se as duas retornaram com Vector2 diferente de 0, pego qual esta mais próxima da posição do objeto (colisão mais próxima)
				#if pos_1.distance_to(object_1.global_position) < pos_2.distance_to(object_1.global_position):
					#result_Pos = pos_1
				#else:
					#result_Pos = pos_2
			#else:
				#if pos_1 == Vector2.ZERO:
					#result_Pos = pos_2
				#elif pos_2 == Vector2.ZERO:
					#result_Pos = pos_1
	#
	#return result_Pos
#
#func verify_collision_between_objects_on_movement_line_after_collision_found(object_1: PhysicsObject2D, subdivisionsNumber: float, final_pos: Vector2) -> Vector2:
	#var result_Pos = final_pos
	#var initial_Pos = object_1.global_position
	#var lerp_step = 1.0 / subdivisionsNumber
	#
	#for i in subdivisionsNumber:
		#var lerp_value = 1.0 - (lerp_step * i)
		#var current_Pos = initial_Pos.lerp(final_pos, lerp_value)
		#
		##print("------------------------------------------")
		##print("subdivisionsNumber = ", i)
		##print("current_Pos = ", current_Pos)
		## posiciono o objeto na posição nova
		#object_1.global_position = current_Pos
		#
		## atualizo as informações do shapecast
		#object_1.shapecast_physics_objects.force_shapecast_update()
		#object_1.shapecast_walls.force_shapecast_update()
		#
		#global_Collision_Check_count += 1
		#
		## Verifico se esta colidindo com outro objeto
		#if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): # Colidiu com algo
			#result_Pos = current_Pos
			## retorno a posição da colisão
			#return result_Pos
	#
	#return result_Pos

#endregion
#endregion
