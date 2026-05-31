extends Node2D
class_name SimulationController

@export var ColResolution2D: CollisionResolution2D

var player_object = preload("res://Componentes/Simulation_AI/Scenes/Player2D_Simulation.tscn")
var ball_object = preload("res://Componentes/Simulation_AI/Scenes/Ball2D_Simulation.tscn")

var PhysicsObjects_List: Array[PhysicsObject2D]

var object_A: PhysicsObject2D
var object_B: PhysicsObject2D

@export var debug: bool

var ball_entered_goal: bool
var ball_entered_enemy_goal: bool

# Tracking para avaliação da IA
var sim_ball_start_x: float
var sim_ball_end_pos: Vector2     # posição final 2D da bola
var sim_ball_last_touch_team: int  # TeamSide do último jogador a tocar a bola, -1 se nenhum
var sim_piece_end_pos: Vector2     # posição final da peça que jogou
var sim_blockers: int              # quantas peças adversárias entre a bola e o gol inimigo


@export var run_num_max_steps: int

@export var max_force_steps: int


func call_get_all_best_plays_rotation(_piece_index: int, _teamSide: int) -> Play:
	#print("pieceTeam = ", _piece_index)
	#print("piece_index = ", _teamSide)
	var play = get_all_best_plays_rotation(rotation_steps, _teamSide, _piece_index)
	return play


func get_best_play_for_team(teamSide: int, piece_indices: Array) -> Play:
	var best_score: float = -INF
	var best_play: Play = null
	
	var pieces_touched := 0
	
	for piece_index in piece_indices:
		get_all_best_plays_rotation(rotation_steps, teamSide, piece_index)
		
		if scored_plays.size() > 0:
			var best_for_piece = scored_plays[0]
			if best_for_piece["bd"]["ctrl"] >= score_control_own:
				pieces_touched += 1
			if best_for_piece["score"] > best_score:
				best_score = best_for_piece["score"]
				best_play = best_for_piece["play"]
	
	if debug_scores:
		var ball_pos_str := "?"
		for obj in ColResolution2D.PhysicsObjects_List:
			if obj.is_in_group("Balls"):
				ball_pos_str = "(%.0f, %.0f)" % [obj.global_position.x, obj.global_position.y]
				break
		print("SUMMARY: %d/%d touched | ball@%s | run_steps=%d forces=%d" % [pieces_touched, piece_indices.size(), ball_pos_str, run_num_max_steps, max_force_steps])
	
	if best_play == null:
		print("No valid play for any piece — fallback toward enemy goal")
		best_play = Play.new()
		best_play.player_index = piece_indices[0] if piece_indices.size() > 0 else 0
		best_play.direction = Vector2.RIGHT if teamSide == 0 else Vector2.LEFT
		best_play.force_lerp = 0.5
		return best_play
	
	# Se a melhor jogada entre todas as peças ainda é ruim,
	# usa fallback mirando no gol adversário com a peça que deu o melhor score
	if best_score <= 0:
		print("Best score is ", best_score, " — fallback toward enemy goal")
		var fallback = Play.new()
		fallback.player_index = best_play.player_index
		fallback.direction = Vector2.RIGHT if teamSide == 0 else Vector2.LEFT
		fallback.force_lerp = 0.5
		return fallback
	
	print("Best overall: piece=", best_play.player_index, " score=", best_score)
	return best_play

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
			instance.teamSide = object.teamSide  # copia lado do time
			add_child(instance)
			
			instance.playerInfo = object.playerInfo
			instance.loadPlayerInfo(object.playerInfo)
			
			if instance.mass != object.mass:
				#print("Dif mass")
				instance.mass = object.mass
				
			if instance.friction != object.friction:
				#print("Dif friction -------")
				#print("instance.friction = ", instance.friction)
				#print("object.friction = ", object.friction)
				instance.friction = object.friction

			PhysicsObjects_List.append(instance)
		
		if object.is_in_group("Balls"):
			var instance = ball_object.instantiate()
			instance.global_position = object.global_position
#			instance.visible = false  # cópia invisível
			instance.add_to_group("Balls")  # necessário para is_in_group() na simulação
			add_child(instance)
			PhysicsObjects_List.append(instance)

func connect_signal() -> void:
	#print("Connecting signals for simulation")
	for object in ColResolution2D.PhysicsObjects_List:
		if object.is_in_group("Players"):
			object.connect("ActionExecuted", Replicate_Action)

func Replicate_Action(index: int, velocity: Vector2, teamSide: int):
	Execute_Physic_Simulation_Run(0.016667, index, velocity, teamSide)

func Execute_Physic_Simulation_Run(_delta: float, play_index: int, play_velocity: Vector2, play_teamSide: int) -> void:
	PhysicsObjects_List[play_index].current_velocity = play_velocity
		
	# garante que todos os objetos estão no lugar que deveriam e com as variaveis corretas
	update_objects_positions_and_variables()
	
	# Reseta lastTouch nas cópias da bola para evitar contaminação
	# de simulações anteriores (bug: update_objects não limpa lastTouch)
	for obj in PhysicsObjects_List:
		if obj.is_in_group("Balls"):
			obj.lastTouch = null
	
	for i in range(PhysicsObjects_List.size()):
		PhysicsObjects_List[i].is_moving = false
	
	ball_entered_goal = false
	ball_entered_enemy_goal = false
	
	# Salva posição inicial da bola para avaliação de avanço
	sim_ball_start_x = 0.0
	for obj in PhysicsObjects_List:
		if obj.is_in_group("Balls"):
			sim_ball_start_x = obj.global_position.x
			break
	
	#print("Simulation Started -------------------------------------")
	#print("Team side = ", play_teamSide)
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
		
		for j in range(PhysicsObjects_List.size()):
			PhysicsObjects_List[j].shapecast_physics_objects.force_update_transform()
			PhysicsObjects_List[j].shapecast_physics_objects.force_shapecast_update()
		
		for object in PhysicsObjects_List:
			if object.is_in_group("Balls"):
				object.shapecast_goals.force_shapecast_update()
				if object.shapecast_goals.is_colliding():
					var collider = object.shapecast_goals.get_collider(0)
					var collider_parent_node = collider.get_parent()
					
					if collider_parent_node.team == play_teamSide:
						ball_entered_goal = true
					else:
						ball_entered_enemy_goal = true
		
		var all_stopped = true
		for j in range(PhysicsObjects_List.size()):
			if PhysicsObjects_List[j].is_moving == true:
				all_stopped = false
		
		if all_stopped == true:
			#print("All objects stopped ------ Simulation Finalized")
			break

		#if i % 100 == 0:
			#print("Step ", i)
	
	#if ball_entered_goal == true:
		#print("Ball Entered Goal")
	#else:
		#print("Ball Not Entered Goal")
	#
	#if ball_entered_enemy_goal == true:
		#print("Ball Entered Enemy Goal")
	#else:
		#print("Ball Not Entered Enemy Goal")
	
	# Coleta posição final, último toque da bola, posição da peça, e bloqueadores
	sim_ball_end_pos = Vector2.ZERO
	sim_ball_last_touch_team = -1
	sim_piece_end_pos = PhysicsObjects_List[play_index].global_position
	for obj in PhysicsObjects_List:
		if obj.is_in_group("Balls"):
			sim_ball_end_pos = obj.global_position
			if obj.lastTouch != null:
				sim_ball_last_touch_team = obj.lastTouch.teamSide
			break
	
	# Conta bloqueadores: peças adversárias entre a bola e o gol inimigo
	sim_blockers = 0
	var enemy_team := 1 if play_teamSide == 0 else 0
	var enemy_goal_x := 1525.0 if play_teamSide == 0 else 283.0
	for obj in PhysicsObjects_List:
		# Usa get("teamSide") em vez de is_in_group pq cópias não estão no grupo Players
		var ts = obj.get("teamSide")
		if ts != null and ts == enemy_team:
			var x_between: bool
			if play_teamSide == 0:  # HOME ataca direita
				x_between = obj.global_position.x > sim_ball_end_pos.x and obj.global_position.x < enemy_goal_x
			else:  # AWAY ataca esquerda
				x_between = obj.global_position.x < sim_ball_end_pos.x and obj.global_position.x > enemy_goal_x
			if x_between and abs(obj.global_position.y - sim_ball_end_pos.y) < 250:
				sim_blockers += 1
		
	#print("Simulation Ended -------------------------------------")

#region IA
@export var rotation_steps: int

# --- Pesos da IA (ajustáveis no inspetor) ---
@export var score_goal: float = 1000.0
@export var score_own_goal: float = -1000.0
@export var score_control_own: float = 200.0
@export var score_control_enemy: float = -200.0
@export var score_advance_per_pixel: float = 0.5
@export var score_proximity_max: float = 150.0   # bônus máximo por ficar perto da bola (decai 0.2/px)
@export var score_defensive_position: float = 20.0  # bônus por ficar entre bola e próprio gol
@export var score_no_contact: float = -150.0        # penalidade por NÃO acertar a bola (perde controle)
@export var score_per_blocker: float = -25.0        # penalidade por cada bloqueador no caminho do gol
@export var debug_scores: bool = true

var scored_plays: Array[Dictionary]


func score_simulation_result(play_teamSide: int, play_index: int) -> Dictionary:
	var b := {"total": 0.0, "ctrl": 0.0, "adv": 0.0, "prox": 0.0, "def": 0.0, "blk": 0.0}
	
	if ball_entered_enemy_goal:
		b["total"] = score_goal; b["ctrl"] = score_goal; return b
	if ball_entered_goal:
		b["total"] = score_own_goal; b["ctrl"] = score_own_goal; return b
	
	if sim_ball_last_touch_team == play_teamSide:
		b["ctrl"] = score_control_own
	elif sim_ball_last_touch_team >= 0:
		b["ctrl"] = score_control_enemy
	
	var advance: float
	if play_teamSide == 0:  # HOME
		advance = sim_ball_end_pos.x - sim_ball_start_x
	else:  # AWAY
		advance = sim_ball_start_x - sim_ball_end_pos.x
	b["adv"] = advance * score_advance_per_pixel
	
	if sim_ball_last_touch_team < 0:
		# Proximidade 2D real entre peça e bola (decai 0.2/px → alcance 750px)
		var dist = sim_piece_end_pos.distance_to(sim_ball_end_pos)
		b["prox"] = maxf(0.0, score_proximity_max - dist * 0.2)
		# Defensivo: peça entre bola e nosso gol (eixo X)
		var def_ok: bool = sim_piece_end_pos.x < sim_ball_end_pos.x if play_teamSide == 0 else sim_piece_end_pos.x > sim_ball_end_pos.x
		if def_ok:
			b["def"] = score_defensive_position
	
	# Penalidade por bloqueadores no caminho do gol (quanto menos, melhor)
	b["blk"] = sim_blockers * score_per_blocker
	
	b["total"] = b["ctrl"] + b["adv"] + b["prox"] + b["def"] + b["blk"]
	if sim_ball_last_touch_team < 0:
		b["total"] += score_no_contact  # penalidade por não acertar a bola
	return b


func get_all_best_plays_rotation(_rotation_steps: int, play_teamSide: int, play_index: int) -> Play:
	scored_plays.clear()
	
	var my_vector = Vector2(1, 0)
	
	if _rotation_steps == 0:
		_rotation_steps = 1
	
	@warning_ignore("integer_division")
	var num_plays = round(360 / _rotation_steps)
	var step = round(360 / num_plays)
	if debug_scores:
		print("num_plays = ", num_plays, " step = ", step)
	
	for k in range(1, max_force_steps + 1):
		var force_lerp = float(k) / float(max_force_steps)
		var force = lerpf(PhysicsObjects_List[play_index].playerInfo_atual.get_min_force(), 
					PhysicsObjects_List[play_index].playerInfo_atual.get_max_force(), 
					force_lerp)
		
		for i in range(num_plays):
			var angle = i * step
			var rotated_vector = my_vector.rotated(deg_to_rad(angle))
			var velocity = rotated_vector * force
			
			Execute_Physic_Simulation_Run(0.016667, play_index, velocity, play_teamSide)
			
			var result = score_simulation_result(play_teamSide, play_index)
			
			var last_play = Play.new()
			last_play.player_index = play_index
			last_play.direction = rotated_vector
			last_play.force_lerp = force_lerp
			scored_plays.append({"play": last_play, "score": result["total"], "bd": result})
	
	# Ordena por score decrescente
	scored_plays.sort_custom(_sort_by_score_desc)
	
	if scored_plays.size() == 0:
		print("No Play available")
		return null
	
	var best = scored_plays[0]
	
	if debug_scores:
		var top_n := mini(3, scored_plays.size())
		print("Piece %d top %d:" % [play_index, top_n])
		for t in top_n:
			var p = scored_plays[t]
			var bd = p["bd"]
			var ang := int(round(rad_to_deg(p["play"].direction.angle()))) % 360
			print("  #%d ang=%d° f=%.2f tot=%.1f [c=%.0f a=%.1f p=%.1f d=%.0f k=%.0f]" % [t+1, ang, p["play"].force_lerp, p["score"], bd["ctrl"], bd["adv"], bd["prox"], bd["def"], bd["blk"]])
	
	return best["play"]


func _sort_by_score_desc(a: Dictionary, b: Dictionary) -> bool:
	return a["score"] > b["score"]

#endregion

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
		object_1.Set_Last_PhysicObject_Collision(object_1.global_position + line_of_impact.normalized() * object_1.radius, object_2)
		object_2.Set_Last_PhysicObject_Collision(object_1.global_position + line_of_impact.normalized() * object_1.radius, object_1)
		return true
	else:
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
	#print("overlap = ", overlap)
	
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
			var new_Pos = PhysicsObjects_List[i].global_position + (PhysicsObjects_List[i].current_velocity * _delta) 
			#verify_collision_between_objects_on_movement_line_LinearSearch(PhysicsObjects_List[i], 10.0, _delta)
			
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
