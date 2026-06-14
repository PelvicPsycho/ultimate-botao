extends Node2D
class_name IA_Controller

@export var physics_controller: CollisionResolution2D
#@export var simulation_controller: SimulationController

var PhysicsObjects_HomeTeam_IndexList: Array[int]
var PhysicsObjects_AwayTeam_IndexList: Array[int]
var PhysicsObjects_Ball_IndexList: Array[int]

enum TeamSide {HOME, AWAY}
var current_TeamSide: TeamSide

var time_to_IA_play: float = 3
var current_time: float = 0

var AI_Pieces_setted: bool = false
var AI_CanRun: bool = false

var AI_NewPlay_Waiting: bool = false

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
@export var AroundPlayer_Mode_rotation_angle_steps: int

@export_group("Around Ball Mode")
@export var AroundBall_Mode_num_steps: int
@export var AroundBall_Mode_step_angle: int

func SetPieceLists() -> void:
	for piece in physics_controller.PhysicsObjects_List:
		if piece.is_in_group("Players"):
			if piece.teamSide == TeamSide.HOME:
				PhysicsObjects_HomeTeam_IndexList.append(piece.index)
			
			if piece.teamSide == TeamSide.AWAY:
				PhysicsObjects_AwayTeam_IndexList.append(piece.index)
			
		elif piece.is_in_group("Balls"):
			PhysicsObjects_Ball_IndexList.append(piece.index)
	
	AI_Pieces_setted = true
	print("AI_Pieces_setted")

func SetCurrentTeamSide(_teamSide: int) -> void:
	current_TeamSide = _teamSide as TeamSide
	
	if current_TeamSide == TeamSide.AWAY:
		print("AI_CanRun")
		physics_controller.Update_pitch_state_variables_on_Simulations(current_TeamSide)
		AI_CanRun = true

func _process(_delta: float) -> void:
	if AI_Pieces_setted and AI_CanRun and physics_controller.Sim_Controller_list[0].current_pitch_state.all_physic_object_list.size() > 0:
		# Reset play lists
		list_of_plays_simulated.clear()
		list_of_plays_to_simulate.clear()
		
		for i in PhysicsObjects_HomeTeam_IndexList.size():
			# get the best piece to play
			current_index = Get_piece_Index_By_Team(current_TeamSide, i)
			
			AI_NewPlay_Waiting = false
			list_play_sorted = false
			list_separated = false
			
			var ball
			for k in physics_controller.current_pitch_state.all_physic_object_list.size():
				if !physics_controller.current_pitch_state.all_physic_object_list[k].is_a_player:
					ball = physics_controller.current_pitch_state.all_physic_object_list[k]
			
			if !physics_controller.verify_collisions_on_path_LinearSearch_NoBall(physics_controller.current_pitch_state.all_physic_object_list[current_index], 10, ball.last_position):
				print("Player ", current_index, " has path to ball free")
				# get a list of plays possible from the piece
				Set_All_Plays_To_Simulate_AroundBall_Mode(AroundBall_Mode_num_steps, AroundBall_Mode_step_angle, AllModes_max_force_steps, current_TeamSide, current_index)

		# Get list size
		var num_p = list_of_plays_to_simulate.size()
		
		if num_p <= 0:
			print("No piece with free path to the ball, AroundPlayer_Mode")
			for i in PhysicsObjects_HomeTeam_IndexList.size():
				# get the best piece to play
				current_index = Get_piece_Index_By_Team(current_TeamSide, i) 
				#Get_Index_Of_Closest_Piece_To_Ball(current_TeamSide)
				
				AI_NewPlay_Waiting = false
				list_play_sorted = false
				list_separated = false

				# get a list of plays possible from the piece
				Set_All_Plays_To_Simulate_AroundPlayer_Mode(AroundPlayer_Mode_rotation_angle_steps, current_TeamSide, current_index)
		
		num_p = list_of_plays_to_simulate.size()
		print("Number of Plays selected = ", num_p)
		
		var slice_size = ceil(float(num_p) / float(physics_controller.num_threads))
		for i in physics_controller.num_threads:
			var initial_index = i * slice_size
			var final_index = ((i + 1) * slice_size)
			
			if final_index >= list_of_plays_to_simulate.size():
				final_index = list_of_plays_to_simulate.size() - 1
			
			var new_list = list_of_plays_to_simulate.slice(initial_index, final_index)
			print("Thread ", i," will simulate ", new_list.size()," plays")
			physics_controller.Sim_Controller_list[i].Simulate_and_Evaluate_Thread_Execution(new_list)
		
		list_separated = true
		AI_CanRun = false
	
	for sim in physics_controller.Sim_Controller_list:
		if sim.simulation_ended and !sim.simulation_data_collected:
			sim.simulation_data_collected = true
			
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
	
	if list_of_plays_simulated.size() >= list_of_plays_to_simulate.size() - 1 and !list_play_sorted and list_separated:
		print("All plays simulated")
		
		sort_by_score(list_of_plays_simulated.size())
		
		print("-------------------------------------")
		
		var max_index = 0
		var max_score = list_of_plays_simulated_Ordered[0].score
		for index in list_of_plays_simulated_Ordered.size():
			var diff = max_score - list_of_plays_simulated_Ordered[index].score
			#if list_of_plays_simulated_Ordered[index].score == list_of_plays_simulated_Ordered[index + 1].score:
			if diff < 200:
				max_index += 1
			else:
				break
		
		print("max_index = ", max_index)
		var play_index = randi_range(0, max_index)
		print("play_index selected = ", play_index)
		print("play selected score = ", list_of_plays_simulated_Ordered[play_index].score)
		
		physics_controller.PhysicsObjects_List[list_of_plays_simulated_Ordered[play_index].player_index].Execute_Action_parameters(list_of_plays_simulated_Ordered[play_index].direction, list_of_plays_simulated_Ordered[play_index].force_lerp)

	#if AI_NewPlay_Waiting:
		#current_time += delta
		#if current_time >= time_to_IA_play:
			##physics_controller.PhysicsObjects_List[current_index].Execute_Action_parameters(new_play.direction, new_play.force_lerp)
			#AI_NewPlay_Waiting = false

func sort_by_score(size_ordered: int):
	list_play_sorted = true
	#list_of_plays_simulated.sort_custom(func(a, b): return a.score > b.score)
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
	
	print("list_of_plays_simulated_Ordered Size = ", list_of_plays_simulated_Ordered.size())
	
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
func Set_All_Plays_To_Simulate_AroundPlayer_Mode(_rotation_angle_steps: int, play_teamSide: int, play_index: int) -> void:
	var my_vector = Vector2(1, 0)
	
	if _rotation_angle_steps == 0:
		_rotation_angle_steps = 1
	
	@warning_ignore("integer_division")
	var num_plays = round(360 / _rotation_angle_steps)
	var step = round(360 / num_plays)
	
	#for k in range(1, AllModes_max_force_steps + 1):
	var force_lerp = 1
	
	var force = lerpf(physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_min_force(), 
				physics_controller.PhysicsObjects_List[play_index].playerInfo_atual.get_max_force(), 
				force_lerp)
	
	for i in range(num_plays):
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
func Set_All_Plays_To_Simulate_AroundBall_Mode(_num_steps: int, _step_angle: int, _max_force_steps: int, play_teamSide: int, play_index: int) -> void:
	if _step_angle == 0:
		_step_angle = 1
	
	var bal_pos = physics_controller.PhysicsObjects_List[PhysicsObjects_Ball_IndexList[0]].global_position
	var bal_radius = physics_controller.PhysicsObjects_List[PhysicsObjects_Ball_IndexList[0]].radius
	
	var piece_pos = physics_controller.PhysicsObjects_List[play_index].global_position
	#var dist_to_ball = piece_pos.distance_to(bal_pos)
	var dir_ball_to_piece = (piece_pos - bal_pos).normalized()
	
	for k in range(1, _max_force_steps + 1):
		var force_lerp = float(k) / float(AllModes_max_force_steps)
		print("force_lerp = ", force_lerp)
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
		
		if _num_steps > 0:
			# calculate the left and right directions
			for i in range(1, _num_steps + 1):
				# Right
				var angle_right = i * _step_angle
				
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
				var angle_left = i * -_step_angle
				
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
