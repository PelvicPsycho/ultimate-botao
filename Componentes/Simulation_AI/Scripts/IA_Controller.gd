extends Node2D
class_name IA_Controller

@export var physics_controller: CollisionResolution2D
@export var match_state: MatchState_AI

var PhysicsObjects_HomeTeam_IndexList: Array[int]
var PhysicsObjects_AwayTeam_IndexList: Array[int]
var PhysicsObjects_Ball_IndexList: Array[int]

enum TeamSide {HOME, AWAY}
var current_TeamSide: TeamSide

@export var max_plays_to_simulate: int
@export var time_to_IA_play: float = 1
var current_time: float = 0

var AI_Pieces_setted: bool = false
var AI_CanRun: bool = false
var AI_Active: bool = false

var list_play_sorted: bool = false
var list_separated: bool = false

var current_piece_index: int

var list_of_plays_simulated: Array[Play]
var list_of_plays_to_simulate: Array[Play]

var list_of_plays_simulated_Ordered: Array[Play]

var current_index: int

@export_group("All Modes")
@export var AllModes_max_force_steps: int

@export_group("Around Player Mode")
@export var AroundPlayer_Mode_angle: int

@export_group("Dificuldade Atual")
var dificuldade_atual
@export var min_for_best_play = 0

func SetPieceLists() -> void:
	print("SetPieceLists")
	for piece in physics_controller.PhysicsObjects_List:
		if piece.is_in_group("Players"):
			if piece.teamSide == TeamSide.HOME:
				PhysicsObjects_HomeTeam_IndexList.append(piece.index)
			
			if piece.teamSide == TeamSide.AWAY:
				PhysicsObjects_AwayTeam_IndexList.append(piece.index)
			
		elif piece.is_in_group("Balls"):
			PhysicsObjects_Ball_IndexList.append(piece.index)
	
	print("HomeTeam = ", PhysicsObjects_HomeTeam_IndexList.size())
	print("AwayTeam = ", PhysicsObjects_AwayTeam_IndexList.size())
	
	SetIADifficulty()
	
	AI_Pieces_setted = true

func SetIADifficulty():
	dificuldade_atual = CupManager.currentCup.cupRank
	if dificuldade_atual == Cup.CUP_RANK.S:
		print("dificuldade_atual = S")
		min_for_best_play = 0
	elif dificuldade_atual == Cup.CUP_RANK.A:
		print("dificuldade_atual = A")
		min_for_best_play = 5
	elif dificuldade_atual == Cup.CUP_RANK.B:
		print("dificuldade_atual = B")
		min_for_best_play = 10
	elif dificuldade_atual == Cup.CUP_RANK.C:
		print("dificuldade_atual = C")
		min_for_best_play = 20
	elif dificuldade_atual == Cup.CUP_RANK.D:
		print("dificuldade_atual = D")
		min_for_best_play = 30
	elif dificuldade_atual == Cup.CUP_RANK.E:
		print("dificuldade_atual = E")
		min_for_best_play = 40
	elif dificuldade_atual == Cup.CUP_RANK.F:
		print("dificuldade_atual = F")
		min_for_best_play = 50

var start_time_AI

func _process(delta: float) -> void:
	if match_state.game_paused == false:
		# All Setted and AI can start choosing the plays it will simulate
		if AI_Pieces_setted and AI_CanRun and physics_controller.Sim_Controller_list[0].current_pitch_state.all_physic_object_list.size() > 0:
			#physics_controller.Sim_Controller_list[0].update_pitch_state_variables(physics_controller.current_pitch_state)
			start_time_AI = Time.get_ticks_usec()
			AI_start_choosing()
		
		# Passes through all simulators and verify if they already simulate and evaluate all plays
		verify_if_all_plays_are_simulated()
		
		# if all simulators ended their simulation and a X time has passed
		if list_of_plays_simulated.size() >= list_of_plays_to_simulate.size() - 1 and !list_play_sorted and list_separated and current_time >= time_to_IA_play: # and !match_state.game_paused
			execute_play()
			var time_taken_AI = (Time.get_ticks_usec() - start_time_AI) / 1000000.0
			print("AI took: ", time_taken_AI, " seconds")
		
		current_time += delta

func sort_by_score(size_ordered: int):
	list_play_sorted = true
	list_of_plays_simulated_Ordered.clear()
	
	for i in size_ordered:
		var score_max = -100000
		var score_max_index = 0
		for j in list_of_plays_simulated.size():
			if list_of_plays_simulated[j].score > score_max:
				score_max = list_of_plays_simulated[j].score
				score_max_index = j
		
		var new_play = Play.new()
		new_play.player_index = list_of_plays_simulated[score_max_index].player_index
		new_play.play_teamSide = list_of_plays_simulated[score_max_index].play_teamSide
		new_play.force_lerp = list_of_plays_simulated[score_max_index].force_lerp
		new_play.direction = list_of_plays_simulated[score_max_index].direction
		new_play.velocity = list_of_plays_simulated[score_max_index].velocity
		new_play.score = list_of_plays_simulated[score_max_index].score
		
		list_of_plays_simulated_Ordered.append(new_play)
		
		list_of_plays_simulated.remove_at(score_max_index)
	
	for play in list_of_plays_simulated_Ordered:
		print("play score = ", play.score)
	
	#list_of_plays_simulated.sort_custom(func(a: Play, b: Play) -> bool: return a.score > b.score)

func Get_piece_Index_By_Team(_teamSide: int, _num: int) -> int:
	if _teamSide == 0:
		return PhysicsObjects_HomeTeam_IndexList[_num]
	elif _teamSide == 1:
		return PhysicsObjects_AwayTeam_IndexList[_num]
	
	return 0

func Get_Index_Of_Closest_Piece_To_Ball(_teamSide: int) -> int:
	var ball = physics_controller.PhysicsObjects_List[PhysicsObjects_Ball_IndexList[0]]
	var min_dist_piece_index = 0
	
	if _teamSide == 0:
		var min_dist = 10000
		for piece in PhysicsObjects_HomeTeam_IndexList:
			var dist = physics_controller.PhysicsObjects_List[piece].global_position.distance_to(ball.global_position)
			if dist < min_dist:
				min_dist = dist
				min_dist_piece_index = piece
		
	elif _teamSide == 1:
		var min_dist = 10000
		for piece in PhysicsObjects_AwayTeam_IndexList:
			var dist = physics_controller.PhysicsObjects_List[piece].global_position.distance_to(ball.global_position)
			
			if dist < min_dist:
				min_dist = dist
				min_dist_piece_index = piece
	
	print("Index selected is ", min_dist_piece_index)
	return min_dist_piece_index

# This function will create a list of plays on the "list_of_plays_to_simulate" list
# On this 'AroundPlayer' mode the plays created will get the directions rotating around player a certain amount of angle
# the smaller the '_rotation_angle_steps' is, greater will be the number of simulations
func Set_All_Plays_To_Simulate_BallDirection_Mode(_num_steps: int, _step_angle: int, _max_force_steps: int, play_teamSide: int, play_index: int) -> void:
	if _step_angle == 0:
		_step_angle = 1
	
	if _num_steps == 0:
		_num_steps = 1
	
	var bal_pos = physics_controller.PhysicsObjects_List[PhysicsObjects_Ball_IndexList[0]].global_position
	var piece_pos = physics_controller.PhysicsObjects_List[play_index].global_position
	var my_vector = (bal_pos - piece_pos).normalized()
	
	var dist_to_ball = piece_pos.distance_to(bal_pos)
	
	if dist_to_ball < 300:
		for k in range(1, _max_force_steps + 1):
			var force_lerp = float(k) / float(AllModes_max_force_steps)
			var force = lerpf(physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_min_force(), 
						physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_max_force(), force_lerp)
			
			# calculate the center direction
			var velocity_center = my_vector * force
			
			var new_play_center = Play.new()
			new_play_center.force_lerp = force_lerp
			new_play_center.player_index = play_index
			new_play_center.play_teamSide = play_teamSide
			new_play_center.direction = my_vector
			new_play_center.velocity = velocity_center
			new_play_center.score = 0
			list_of_plays_to_simulate.append(new_play_center)
				
			# calculate the left and right directions
			for i in range(1, _num_steps + 1):
				var angle_right = i * _step_angle
				var angle_left = i * -_step_angle
				
				var direction_right = my_vector.rotated(deg_to_rad(angle_right))
				var direction_left = my_vector.rotated(deg_to_rad(angle_left))
				
				var velocity_right = direction_right * force
				var velocity_left = direction_left * force
				
				var new_play_right = Play.new()
				new_play_right.force_lerp = force_lerp
				new_play_right.player_index = play_index
				new_play_right.play_teamSide = play_teamSide
				new_play_right.direction = direction_right
				new_play_right.velocity = velocity_right
				new_play_right.score = 0
				list_of_plays_to_simulate.append(new_play_right)
				
				var new_play_left = Play.new()
				new_play_right.force_lerp = force_lerp
				new_play_right.player_index = play_index
				new_play_right.play_teamSide = play_teamSide
				new_play_right.direction = direction_left
				new_play_right.velocity = velocity_left
				new_play_right.score = 0
				list_of_plays_to_simulate.append(new_play_left)

# This function will create a list of plays on the "list_of_all_plays_to_simulate" list
# On this 'AroundPlayer' mode the plays created will get the directions rotating around player a certain amount of angle
# the smaller the '_rotation_angle_steps' is, greater will be the number of simulations
func Set_All_Plays_To_Simulate_AroundPlayer_Mode(max_plays: int, play_teamSide: int, play_index: int) -> void:
	var my_vector = Vector2(1, 0)
	
	@warning_ignore("integer_division")
	var step = round(360 / max_plays)

	#for k in range(1, AllModes_max_force_steps + 1):
	var force_lerp = 1
	var force = lerpf(physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_min_force(), 
				physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_max_force(), 
				force_lerp)
	
	for i in range(max_plays):
		var angle = i * step
		var direction = my_vector.rotated(deg_to_rad(angle))
		var velocity = direction * force
		
		var new_play = Play.new()
		new_play.force_lerp = force_lerp
		new_play.player_index = play_index
		new_play.play_teamSide = play_teamSide
		new_play.direction = direction
		new_play.velocity = velocity
		new_play.score = 0
		list_of_plays_to_simulate.append(new_play)

# This function will create a list of plays on the "list_of_plays_to_simulate" list
# On this 'AroundBall' mode the plays created will get the directions rotating around ball a certain amount of angle
# the smaller the '_rotation_angle_steps' is, greater will be the number of simulations
func Set_All_Plays_To_Simulate_AroundBall_Mode(max_plays: int, _max_force_steps: int, play_teamSide: int, play_index: int) -> void:
	@warning_ignore("integer_division")
	var num_steps = ceil((max_plays / 2) / _max_force_steps) - 1
	var angle_steps = 80 / num_steps
	
	var bal_pos = physics_controller.PhysicsObjects_List[PhysicsObjects_Ball_IndexList[0]].global_position
	var bal_radius = physics_controller.PhysicsObjects_List[PhysicsObjects_Ball_IndexList[0]].radius
	
	var piece_pos = physics_controller.PhysicsObjects_List[play_index].global_position
	#var dist_to_ball = piece_pos.distance_to(bal_pos)
	var dir_ball_to_piece = (piece_pos - bal_pos).normalized()
	
	for k in range(1, _max_force_steps + 1):
		var force_lerp = float(k) / float(AllModes_max_force_steps)
		var force = lerpf(physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_min_force(), 
					physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_max_force(), force_lerp)
		
		# calculate the center direction
		var position_center = bal_pos + (dir_ball_to_piece * bal_radius)
		var dir_to_center = (position_center - piece_pos).normalized()
		var velocity_center = dir_to_center * force
		
		var new_play_center = Play.new()
		new_play_center.force_lerp = force_lerp
		new_play_center.player_index = play_index
		new_play_center.play_teamSide = play_teamSide
		new_play_center.direction = dir_to_center
		new_play_center.velocity = velocity_center
		new_play_center.score = 0
		
		list_of_plays_to_simulate.append(new_play_center)
		
		if num_steps > 0:
			# calculate the left and right directions
			for i in range(1, num_steps + 1):
				# Right
				var angle_right = i * angle_steps
				
				var direction_right = dir_ball_to_piece.rotated(deg_to_rad(angle_right))
				var position_right = bal_pos + (direction_right * bal_radius)
				var dir_to_right = (position_right - piece_pos).normalized()
				var velocity_right = dir_to_right * force
				
				var new_play_right = Play.new()
				new_play_right.force_lerp = force_lerp
				new_play_right.player_index = play_index
				new_play_right.play_teamSide = play_teamSide
				new_play_right.direction = dir_to_right
				new_play_right.velocity = velocity_right
				new_play_right.score = 0
				
				list_of_plays_to_simulate.append(new_play_right)
				
				# Left
				var angle_left = i * -angle_steps
				
				var direction_left = dir_ball_to_piece.rotated(deg_to_rad(angle_left))
				var position_left = bal_pos + (direction_left * bal_radius)
				var dir_to_left = (position_left - piece_pos).normalized()
				var velocity_left = dir_to_left * force
				
				var new_play_left = Play.new()
				new_play_left.force_lerp = force_lerp
				new_play_left.player_index = play_index
				new_play_left.play_teamSide = play_teamSide
				new_play_left.direction = dir_to_left
				new_play_left.velocity = velocity_left
				new_play_left.score = 0
				
				list_of_plays_to_simulate.append(new_play_left)

func Get_Random_Piece_Index() -> int:
	if current_TeamSide == TeamSide.HOME:
		return PhysicsObjects_HomeTeam_IndexList.pick_random()
	elif current_TeamSide == TeamSide.AWAY:
		return PhysicsObjects_AwayTeam_IndexList.pick_random()
	
	return -1

func SetCurrentTeamSide(_teamSide: int) -> void:
	current_TeamSide = _teamSide as TeamSide
	
	if current_TeamSide == TeamSide.AWAY:
		print("AI_CanRun")
		physics_controller.Update_pitch_state_variables_on_Simulations(current_TeamSide)
		AI_CanRun = true
		current_time = 0

# All Setted and AI can start choosing the plays it will simulate
func AI_start_choosing() -> void:
	# Reset play lists
	list_of_plays_simulated.clear()
	list_of_plays_to_simulate.clear()
	
	var ball
	for k in physics_controller.current_pitch_state.all_physic_object_list.size():
		if !physics_controller.current_pitch_state.all_physic_object_list[k].is_a_player:
			ball = physics_controller.current_pitch_state.all_physic_object_list[k]
	
	list_play_sorted = false
	list_separated = false
		
	var index_list = []
	for i in PhysicsObjects_HomeTeam_IndexList.size():
		# get the best piece to play
		current_index = Get_piece_Index_By_Team(current_TeamSide, i)
		
		if !physics_controller.verify_collisions_on_path_LinearSearch_NoBall(physics_controller.current_pitch_state.all_physic_object_list[current_index], 10, ball.last_position):
			index_list.append(current_index)
	
	if index_list.size() > 0:
		#print("index_list.size = ", index_list.size())
		@warning_ignore("integer_division")
		var num_of_plays_to_each_piece = ceil(max_plays_to_simulate / index_list.size())
		#print("num_of_plays_to_each_piece = ", num_of_plays_to_each_piece)
		for i in index_list:
			#print("Player ", i, " has path to ball free")
			# get a list of plays possible from the piece
			Set_All_Plays_To_Simulate_AroundBall_Mode(num_of_plays_to_each_piece, AllModes_max_force_steps, current_TeamSide, i)
	
	# Get current play list size
	var num_p = list_of_plays_to_simulate.size()
	
	if num_p <= 0:
		print("No piece with free path to the ball, AroundPlayer_Mode")
		var num_of_plays_to_each_piece = ceil(max_plays_to_simulate / PhysicsObjects_HomeTeam_IndexList.size())
		for i in PhysicsObjects_HomeTeam_IndexList.size():
			# get the best piece to play
			current_index = Get_piece_Index_By_Team(current_TeamSide, i) 
			#Get_Index_Of_Closest_Piece_To_Ball(current_TeamSide)

			list_play_sorted = false
			list_separated = false

			# get a list of plays possible from the piece
			Set_All_Plays_To_Simulate_AroundPlayer_Mode(num_of_plays_to_each_piece, current_TeamSide, current_index)
	
	num_p = list_of_plays_to_simulate.size()
	print("list_of_plays_to_simulate = ", list_of_plays_to_simulate.size())
	
	slice_list_and_send_to_thread_simulate(num_p)
	
	list_separated = true
	AI_CanRun = false
	current_time = 0

func slice_list_and_send_to_thread_simulate(num_plays: int) -> void:
	var slice_size = ceil(float(num_plays) / float(physics_controller.num_threads))
	for i in physics_controller.num_threads:
		var initial_index = i * slice_size
		var final_index = ((i + 1) * slice_size)
		
		if final_index >= list_of_plays_to_simulate.size():
			final_index = list_of_plays_to_simulate.size()
		
		var new_list = list_of_plays_to_simulate.slice(initial_index, final_index)
		print("Thread ", i," will simulate ", new_list.size()," plays")
		physics_controller.Sim_Controller_list[i].Simulate_and_Evaluate_Thread_Execution(new_list)

# Passes through all simulators and verify if they already simulate and evaluate all plays
func verify_if_all_plays_are_simulated() -> void:
	for sim in physics_controller.Sim_Controller_list:
		if sim.simulation_ended and !sim.simulation_data_collected:
			sim.simulation_data_collected = true
			
			# Copy the plays to the list "list_of_plays_simulated"
			for play in sim.list_of_plays_simulated:
				var new_play = Play.new()
				new_play.player_index = play.player_index
				new_play.play_teamSide = play.play_teamSide
				new_play.force_lerp = play.force_lerp
				new_play.direction = play.direction
				new_play.velocity = play.velocity
				new_play.score = play.score
				
				list_of_plays_simulated.append(play)
			
			print("list_of_plays_simulated = ", list_of_plays_simulated.size())

# if all simulators ended their simulation and a X time has passed
func execute_play() -> void:
	print("All plays simulated ------------------------")
	
	# sort "list_of_plays_simulated" by their score
	sort_by_score(list_of_plays_simulated.size())
	
	# Sets the plays the AI will replicate
	var max_index = 0
	var max_score = list_of_plays_simulated_Ordered[0].score
	for index in list_of_plays_simulated_Ordered.size():
		var diff = max_score - list_of_plays_simulated_Ordered[index].score
		if diff < 100:
			max_index += 1
		else:
			break
	
	var play_index = 0
	var r = randi_range(0,100)
	
	if r >= min_for_best_play:
		print("Best Play")
		play_index = randi_range(0, max_index)
	else:
		print("Get Random Play By Difficulty")
		var pivot = (list_of_plays_simulated_Ordered.size()-1)#/2
		play_index = GetRandomPlayByDifficulty(pivot)#randi_range(0, max_index)
	
	print("Play selected index = ", play_index)
	print("Play selected force_lerp = ", list_of_plays_simulated_Ordered[play_index].force_lerp)
	print("Play selected Score = ", list_of_plays_simulated_Ordered[play_index].score)
	
	var current_pitch_state_score =  physics_controller.Sim_Controller_list[0].evaluate_pitch_state_based_on_team(physics_controller.current_pitch_state, current_TeamSide)
	
	if current_pitch_state_score > list_of_plays_simulated_Ordered[play_index].score:
		use_card_on_selected_piece(list_of_plays_simulated_Ordered[play_index].player_index)
	
	physics_controller.PhysicsObjects_List[list_of_plays_simulated_Ordered[play_index].player_index].Execute_Action_parameters(list_of_plays_simulated_Ordered[play_index].direction, list_of_plays_simulated_Ordered[play_index].force_lerp)
	current_time = 0

func use_card_on_selected_piece(_piece_index: int) -> void:
	var player_info = physics_controller.PhysicsObjects_List[_piece_index].playerInfo_atual
	
	# SEGURANÇA: Verifica se o array existe e se não está vazio
	if player_info.slotsUpgrates == null or player_info.slotsUpgrates.size() == 0:
		print("DEBUG: Peça ", _piece_index, " não possui cartas nos slots.")
		return

	# Agora é seguro calcular o índice
	var max_idx = player_info.slotsUpgrates.size() - 1
	var card_index = randi_range(0, max_idx)
	
	var card = player_info.slotsUpgrates[card_index]
	if card != null:
		if card.nome == "Gigantificação":
			#print(" -- Card - Name = ", card.nome)
			match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[_piece_index], card)
			#break
		elif card.nome == "Magnetismo":
			#print(" -- Card - Name = ", card.nome)
			match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[_piece_index], card)
			#break
		elif card.nome == "Minimização":
			#print(" -- Card - Name = ", card.nome)
			match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[_piece_index], card)
			#break
		elif card.nome == "Chute Forte":
			#print(" -- Card - Name = ", card.nome)
			match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[_piece_index], card)
			#break
		elif card.nome == "Onda de shock":
			#print(" -- Card - Name = ", card.nome)
			match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[_piece_index], card)
			#break
		#else:
			#print(" -- Card - Other = ", card.nome)
	#else:
		#print(" -- Card - Null")

#func use_card_test() -> void:
	#print("Cards Test ------------------------------------------")
	#for i in PhysicsObjects_AwayTeam_IndexList:
		##physics_controller.PhysicsObjects_List[i].playerInfo_atual.slotsUpgrates.size()
		#print("Card - Piece Index = ", i)
		#for card in physics_controller.PhysicsObjects_List[i].playerInfo_atual.slotsUpgrates:
			##print("Card = ", card)
			#if card != null:
				#if card.nome == "Carta Aumento De Tamanho":
					#print(" -- Card - Name = ", card.nome)
					#match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[i], card)
					#break
				#elif card.nome == "Atração":
					#print(" -- Card - Name = ", card.nome)
					#match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[i], card)
					#break
				#elif card.nome == "Carta Encolhedora":
					#print(" -- Card - Name = ", card.nome)
					#match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[i], card)
					#break
				#elif card.nome == "Corre Peao":
					#print(" -- Card - Name = ", card.nome)
					#match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[i], card)
					#break
				#elif card.nome == "Onda de shock":
					#print(" -- Card - Name = ", card.nome)
					#match_state.tentar_usar_carta(physics_controller.PhysicsObjects_List[i], card)
					#break
			#else:
				#print(" -- Card - Null")

func GetRandomPlayByDifficulty(max_index: int) -> int:
	if dificuldade_atual == Cup.CUP_RANK.S and max_index > 3:
		return randi_range(3, max_index)
	elif dificuldade_atual == Cup.CUP_RANK.A  and max_index > 6:
		return randi_range(6, max_index)
	elif dificuldade_atual == Cup.CUP_RANK.B  and max_index > 9:
		return randi_range(9, max_index)
	elif dificuldade_atual == Cup.CUP_RANK.C  and max_index > 12:
		return randi_range(12, max_index)
	elif dificuldade_atual == Cup.CUP_RANK.D  and max_index > 15:
		return randi_range(15, max_index)
	elif dificuldade_atual == Cup.CUP_RANK.E  and max_index > 18:
		return randi_range(18, max_index)
	elif dificuldade_atual == Cup.CUP_RANK.F  and max_index > 21:
		return randi_range(21, max_index)
	
	return max_index#randi_range(0, max_index)
