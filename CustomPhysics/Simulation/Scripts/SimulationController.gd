extends Node2D
class_name SimulationController

@export var ColResolution2D: CollisionResolution2D

var player_object = preload("res://CustomPhysics/Simulation/Scenes/Player2D_Simulation_NoVisuals.tscn")
var ball_object = preload("res://CustomPhysics/Simulation/Scenes/Ball2D_Simulation_NoVisuals.tscn")

var PhysicsObjects_List: Array[PhysicsObject2D]

func _ready() -> void:
	pass

func update_objects_positions_and_variables() -> void:
	for i in ColResolution2D.PhysicsObjects_List.size():
		PhysicsObjects_List[i].global_position = ColResolution2D.PhysicsObjects_List[i].global_position
		PhysicsObjects_List[i].mass = ColResolution2D.PhysicsObjects_List[i].mass
		PhysicsObjects_List[i].friction = ColResolution2D.PhysicsObjects_List[i].friction


func create_objects_copy() -> void:
	for object in ColResolution2D.PhysicsObjects_List:
		if object.is_in_group("Players"):
			var instance = player_object.instantiate()
			instance.global_position = object.global_position
			instance.index = object.index
			instance.name = "PLayer_" + str(object.index)
			instance.scale = object.scale
			add_child(instance)
			
			instance.playerInfo = object.playerInfo
			instance.loadPlayerInfo(object.playerInfo)
			
			if instance.mass != object.mass:
				print("Dif mass")
				
			if instance.friction != object.friction:
				print("Dif friction")
			
			PhysicsObjects_List.append(instance)
		
		if object.is_in_group("Balls"):
			var instance = ball_object.instantiate()
			instance.global_position = object.global_position
			add_child(instance)
			PhysicsObjects_List.append(instance)

func connect_signal() -> void:
	for object in ColResolution2D.PhysicsObjects_List:
		if object.is_in_group("Players"):
			object.connect("ActionExecuted", Replicate_Action)

func Replicate_Action(index: int, velocity: Vector2):
	print("Iniciou a simulação")
	PhysicsObjects_List[index].current_velocity = velocity
	
	Execute_Physic_Simulation_Run(0.016667, 1500)
	
	print("Terminou a simulação")

var object_A: PhysicsObject2D
var object_B: PhysicsObject2D

@export var debug: bool

func Execute_Physic_Simulation_Run(_delta: float, num_max_steps: int) -> void:
	# garante que todos os objetos estão no lugar que deveriam e com as variaveis corretas
	update_objects_positions_and_variables()
	
	for i in range(PhysicsObjects_List.size()):
		PhysicsObjects_List[i].is_moving = false

	print("Simulation Started -------------------------------------")
	for i in range(num_max_steps + 1):
		#
		# verify physic objects collisions
		collision_physics_object_resolution()
		#
		#
		# update the movemente of all physic objects
		movement_update(0.016667)
		#
		#
		# verify walls collisions
		collision_wall_resolution()
		#
		
		for j in range(PhysicsObjects_List.size()):
			PhysicsObjects_List[j].shapecast_physics_objects.force_update_transform()
			PhysicsObjects_List[j].shapecast_physics_objects.force_shapecast_update()
		
		var all_stopped = true
		for j in range(PhysicsObjects_List.size()):
			if PhysicsObjects_List[j].is_moving == true:
				all_stopped = false
		
		if all_stopped == true:
			print("All objects stopped ------ Simulation Finalized")
			break

		#if i % 100 == 0:
		print("Step ", i)
	
	print("Simulation Ended -------------------------------------")

#region Physics Objects Collisions
func collision_physics_object_resolution() -> void:
	for i in range(PhysicsObjects_List.size()):
		object_A = PhysicsObjects_List[i]
		for j in range(i + 1, PhysicsObjects_List.size()):
			object_B = PhysicsObjects_List[j]
			if has_collision_physics_object(object_A, object_B):
				handle_physics_objects_collision(object_A, object_B)

func has_collision_physics_object(object_1: PhysicsObject2D, object_2: PhysicsObject2D) -> bool:
	var line_of_impact = object_2.global_position - object_1.global_position
	var distance = line_of_impact.length()
	
	var overlap = distance - (object_1.radius + object_2.radius)

	#print("Overlap = ", overlap)
	
	if overlap <= 0:
		#print("Estao dentro um do outro")
		return true
	else:
		return false
	
	 #talvez eu tenha que atualizar o shapecast de todos os objetos antes de  pegar a colisão de alguem
	 #no momento eu apenas atualizo o do objeto atual
	#
	#object_1.shapecast_physics_objects.force_shapecast_update()
	#
	#if object_1.shapecast_physics_objects.is_colliding():
		#for i in object_1.shapecast_physics_objects.get_collision_count():
			#var collider = object_1.shapecast_physics_objects.get_collider(i)
			#if collider == object_2:
#
				#return true
	#else:
		#object_1.last_position_without_collision = object_1.global_position
		#
	#return false

func handle_physics_objects_collision(object_1: PhysicsObject2D, object_2: PhysicsObject2D) -> void:
	var sum_masses = object_1.mass + object_2.mass
	var line_of_impact = object_2.global_position - object_1.global_position
	var distance = line_of_impact.length()
	var velocity_Diff = object_2.current_velocity - object_1.current_velocity

	# Handle Objects Overlap
	if handle_physics_objects_inside_each_other(object_1, object_2, distance, line_of_impact):
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
		
		#print("---------- Simulation Colision ----------")
		#print("Object_1 ", object_1.name," New Velocity = ", object_1.current_velocity)
		#print("Object_2 ", object_2.name," New Velocity = ", object_2.current_velocity)
		#print("----------")


func handle_physics_objects_inside_each_other(object_1: PhysicsObject2D, object_2: PhysicsObject2D, distance: float, line_of_impact: Vector2) -> bool:
	var overlap = distance - (object_1.radius + object_2.radius)
	#print("Overlap = ", overlap)
	
	if overlap <= 0:
		#print("Estao dentro um do outro")
		overlap = abs(overlap)

		line_of_impact = line_of_impact.normalized()
		
		object_1.global_position = object_1.global_position + ((-line_of_impact * (overlap * 0.51)))
		object_2.global_position = object_2.global_position + ((line_of_impact * (overlap * 0.51)))

		return true
	else:
		#print("Não Estao dentro um do outro")
		return false
		

#endregion

#region Physics Wall Collisions
func collision_wall_resolution() -> void:
	for i in range(PhysicsObjects_List.size()):
		object_A = PhysicsObjects_List[i]
		if has_collision_wall(object_A):
			#print("Collided with a wall")
			handle_walls_collision(object_A)

func has_collision_wall(physic_object: PhysicsObject2D) -> bool:
	physic_object.shapecast_walls.force_shapecast_update()

	if physic_object.shapecast_walls.is_colliding():
		for i in physic_object.shapecast_walls.get_collision_count():
			return true

	return false
	
func handle_walls_collision(object_1: PhysicsObject2D) -> void:
	# Get the normal of the wall we hit
	var normal = object_1.shapecast_walls.get_collision_normal(0)
	
	handle_physics_objects_inside_wall(object_1)
	
	# Reflect the velocity vector
	object_1.current_velocity = object_1.current_velocity.bounce(normal)

func handle_physics_objects_inside_wall(object_1: PhysicsObject2D) -> void:
	var collision_point = object_1.shapecast_walls.get_collision_point(0)
	var line_of_impact = collision_point - object_1.global_position
	var distance_from_impact = line_of_impact.length()
	
	var overlap = distance_from_impact - object_1.radius
	overlap = abs(overlap)
	
	line_of_impact = line_of_impact.normalized()
	
	object_1.global_position = object_1.global_position + (-line_of_impact * overlap) * 1.1
#endregion

#region Movement
var global_Collision_Check_count: int

func movement_update(_delta: float) -> void:
	for i in range(PhysicsObjects_List.size()):
		# chama função do object que atualiza sua Velocity
		var new_velocity = PhysicsObjects_List[i].current_velocity * PhysicsObjects_List[i].friction;
		
		var vel_x = abs(PhysicsObjects_List[i].current_velocity.x)
		var vel_y = abs(PhysicsObjects_List[i].current_velocity.y)
		
		if vel_x < 10 && vel_y < 10:
			PhysicsObjects_List[i].Set_Current_Velocity(Vector2.ZERO)
			PhysicsObjects_List[i].is_moving = false
		else:
			PhysicsObjects_List[i].Set_Current_Velocity(new_velocity)
			PhysicsObjects_List[i].is_moving = true
		
		if PhysicsObjects_List[i].is_moving:
			global_Collision_Check_count = 0
			# Acha a proxima posição do objeto
			# - Percorre o caminho que o objeto iria passar entre um frame e outro
			# - Caso tenha alguma colisão no meio do caminho, retorna a posição dessa colisão
			#var new_Pos = verify_collision_between_objects_on_movement_line_BooleanSearch(PhysicsObjects_List[i], 2.0, _delta)
			
			var new_Pos = PhysicsObjects_List[i].global_position + (PhysicsObjects_List[i].current_velocity * _delta) #verify_collision_between_objects_on_movement_line_LinearSearch(PhysicsObjects_List[i], 10.0, _delta)
			
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
	var circle_shape_object_1: CircleShape2D = object_1.shapecast_physics_objects.shape as CircleShape2D
	var radius_object_1: float = circle_shape_object_1.radius
	
	if inicial_Pos.distance_to(final_Pos) < radius_object_1:
		#print("Distance Too Small")
		return final_Pos
	
	#print("Start --------------")
	var result_Pos = final_Pos
	var lerp_step = 1.0 / subdivisionsNumber
	#print("lerp_step = ", lerp_step)
	
	for i in range(0.0, subdivisionsNumber + 1):
		var lerp_value = lerp_step * i
		var current_Pos = inicial_Pos.lerp(final_Pos, lerp_value)

		# posiciono o objeto na posição nova
		object_1.global_position = current_Pos
		
		# atualizo as informações do shapecast
		#object_1.shapecast_physics_objects.force_update_transform()
		object_1.shapecast_physics_objects.force_shapecast_update()
		object_1.shapecast_walls.force_shapecast_update()
		
		global_Collision_Check_count += 1
		
		# Verifico se esta colidindo com outro objeto
		if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): # Colidiu com algo
			result_Pos = current_Pos
			
			#print("Colidiu com algum objeto, Para")
			# retorno a posição da colisão
			return result_Pos
	
	object_1.global_position = inicial_Pos
	
	return result_Pos


# Faz verificações de colisões entre a posição atual do objeto e a sua próxima posição (posição depois de se mover no proximo frame)
# "subdivisionsNumber" é a quantidade de verifições
# Usa a lógica de uma busca binária
func verify_collision_between_objects_on_movement_line_BooleanSearch(object_1: PhysicsObject2D, subdivisionsNumber: float, _delta: float) -> Vector2:
	var inicial_Pos = object_1.global_position
	var final_Pos = object_1.global_position + (object_1.current_velocity * _delta)
	
	var result_Pos = final_Pos
	
	#print("Start --------------")
	#print("final_Pos = ", final_Pos)
	
	var circle_shape_object_1: CircleShape2D = object_1.shapecast_physics_objects.shape as CircleShape2D
	var radius_object_1: float = circle_shape_object_1.radius
	
	if inicial_Pos.distance_to(final_Pos) < radius_object_1:
		#print("Distance Too Small")
		return final_Pos
	
	# verifico se aconteceu alguma colisão na posição final
	object_1.global_position = final_Pos
	#object_1.shapecast_physics_objects.force_update_transform()
	object_1.shapecast_physics_objects.force_shapecast_update()
	object_1.shapecast_walls.force_shapecast_update()

	global_Collision_Check_count += 1
	
	# posição final esta colidindo com outro objeto, então verificar posições anteriores para pegar a posição mais precisa da colisão
	if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): 
		result_Pos = object_1.global_position
		#print("final position has collision")
	# posição final não colidiu com nada, então verificar posições anteriores
	else:
		#print("final position has NO collision")
		result_Pos = verify_collision_between_objects_on_movement_line_recursive(object_1, subdivisionsNumber, inicial_Pos, final_Pos)
	
	# colidiu com algo
	if result_Pos != Vector2.ZERO: 
		# tenta achar a posição mais próxima do objeto mas que continue tendo colisão
		return result_Pos #= #verify_collision_between_objects_on_movement_line_after_collision_found(object_1, subdivisionsNumber, result_Pos)
	# Não colidiu com nada, retorna a posição final do movimento
	else:
		result_Pos = final_Pos
	
	object_1.global_position = inicial_Pos
	
	return result_Pos

func verify_collision_between_objects_on_movement_line_recursive(object_1: PhysicsObject2D, subdivisionsNumber: float, inicial_Pos: Vector2, final_Pos: Vector2) -> Vector2:
	var current_Pos = inicial_Pos.lerp(final_Pos, 0.5)
	var result_Pos = Vector2.ZERO
	#print("------------------------------------------")
	#print("subdivisionsNumber = ", subdivisionsNumber)
	#print("current_Pos = ", current_Pos)
	# posiciono o objeto na posição nova
	object_1.global_position = current_Pos
	
	# atualizo as informações do shapecast
	#object_1.shapecast_physics_objects.force_update_transform()
	object_1.shapecast_physics_objects.force_shapecast_update()
	object_1.shapecast_walls.force_shapecast_update()
	
	global_Collision_Check_count += 1
	
	# Verifico se esta colidindo com outro objeto
	if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): # Colidiu com algo
		result_Pos = current_Pos
		
		# retorno a posição da colisão
		return result_Pos
	else: # Nao Colidiu
		# diminuo a quantidade de subdivisões para serem feites
		subdivisionsNumber -= 1
		
		# verifico se ainda pode procurar mais
		if subdivisionsNumber > 0:
			var pos_1 = Vector2.ZERO
			var pos_2 = Vector2.ZERO
			
			# defino as variaveis para procurar na metade anterior ao meio (inicio -> meio)
			var new_inicial_Pos = inicial_Pos
			var new_final_Pos = current_Pos
			
			var circle_shape_object_1: CircleShape2D = object_1.shapecast_physics_objects.shape as CircleShape2D
			var radius_object_1: float = circle_shape_object_1.radius
			
			if new_inicial_Pos.distance_to(new_final_Pos) > radius_object_1:
				pos_1 = verify_collision_between_objects_on_movement_line_recursive(object_1, subdivisionsNumber, new_inicial_Pos, new_final_Pos)
			
			# defino as variaveis para procurar na metade posterior ao meio (meio -> final)
			new_inicial_Pos = current_Pos
			new_final_Pos = final_Pos
			
			if new_inicial_Pos.distance_to(new_final_Pos) > radius_object_1:
				pos_2 = verify_collision_between_objects_on_movement_line_recursive(object_1, subdivisionsNumber, new_inicial_Pos, new_final_Pos)
			
			# Verifico se alguma retornou colisão (retornou um Vector2 diferente de 0)
			if pos_1 != Vector2.ZERO and pos_2 != Vector2.ZERO:
				# se as duas retornaram com Vector2 diferente de 0, pego qual esta mais próxima da posição do objeto (colisão mais próxima)
				if pos_1.distance_to(object_1.global_position) < pos_2.distance_to(object_1.global_position):
					result_Pos = pos_1
				else:
					result_Pos = pos_2
			else:
				if pos_1 == Vector2.ZERO:
					result_Pos = pos_2
				elif pos_2 == Vector2.ZERO:
					result_Pos = pos_1
	
	return result_Pos

func verify_collision_between_objects_on_movement_line_after_collision_found(object_1: PhysicsObject2D, subdivisionsNumber: float, final_pos: Vector2) -> Vector2:
	var result_Pos = final_pos
	var initial_Pos = object_1.global_position
	var lerp_step = 1.0 / subdivisionsNumber
	
	for i in subdivisionsNumber:
		var lerp_value = 1.0 - (lerp_step * i)
		var current_Pos = initial_Pos.lerp(final_pos, lerp_value)
		
		#print("------------------------------------------")
		#print("subdivisionsNumber = ", i)
		#print("current_Pos = ", current_Pos)
		# posiciono o objeto na posição nova
		object_1.global_position = current_Pos
		
		# atualizo as informações do shapecast
		#object_1.shapecast_physics_objects.force_update_transform()
		object_1.shapecast_physics_objects.force_shapecast_update()
		object_1.shapecast_walls.force_shapecast_update()
		
		global_Collision_Check_count += 1
		
		# Verifico se esta colidindo com outro objeto
		if object_1.shapecast_physics_objects.is_colliding() or object_1.shapecast_walls.is_colliding(): # Colidiu com algo
			result_Pos = current_Pos
			# retorno a posição da colisão
			return result_Pos
	
	return result_Pos
#endregion
