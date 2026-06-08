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

var current_index: int

@export var rotation_angle_steps: int
@export var max_force_steps: int

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
		AI_CanRun = true

func _process(_delta: float) -> void:
	if AI_Pieces_setted and AI_CanRun and physics_controller.Sim_Controller_list[0].current_pitch_state.all_physic_object_list.size() > 0:
		# get the best piece to play
		current_index = Select_Best_Piece_To_Play(current_TeamSide)
		
		AI_NewPlay_Waiting = false
		list_play_sorted = false
		list_separated = false
		
		if current_piece_index >= 0:
			# Reset play lists
			list_of_plays_simulated.clear()
			list_of_plays_to_simulate.clear()
			
			# get a list of plays possible from the piece
			Set_All_Plays_To_Simulate_AroundPlayer_Mode(rotation_angle_steps, current_TeamSide, current_index)
			
			var num_p = list_of_plays_to_simulate.size()
			#print("Number of Plays = ", num_p)
			
			var slice_size = num_p / physics_controller.num_threads
			#print("slice_size = ", slice_size)
			
			for i in physics_controller.num_threads:
				var initial_index = i * slice_size
				var final_index = ((i + 1) * slice_size)
				
				#print("initial_index = ", initial_index)
				#print("final_index = ", final_index)
				
				var new_list = list_of_plays_to_simulate.slice(initial_index, final_index)
				physics_controller.Sim_Controller_list[i].Simulate_and_Evaluate_Thread_Execution(new_list)
			
			list_separated = true
			current_time = 0
			
			AI_CanRun = false
	
	for sim in physics_controller.Sim_Controller_list:
		if sim.simulation_ended and !sim.simulation_data_collected:
			sim.simulation_data_collected = true
			
			for play in sim.list_of_plays_simulated:
				list_of_plays_simulated.append(play)
		
			#for play in list_of_plays_simulated:
				#print("play score = ", play.score)
			
			#print("list_of_plays_simulated = ", list_of_plays_simulated.size())
	
	if list_of_plays_simulated.size() >= list_of_plays_to_simulate.size() and !list_play_sorted and list_separated:
		print("All plays simulated")
		sort_by_score()
		#physics_controller.PhysicsObjects_List[current_index].Execute_Action_parameters(new_play.direction, new_play.force_lerp)
	
	#if AI_NewPlay_Waiting:
		#current_time += delta
		#if current_time >= time_to_IA_play:
			##physics_controller.PhysicsObjects_List[current_index].Execute_Action_parameters(new_play.direction, new_play.force_lerp)
			#AI_NewPlay_Waiting = false

func sort_by_score():
	list_play_sorted = true
	list_of_plays_simulated.sort_custom(func(a, b): return a.score > b.score)
	
	#for play in list_of_plays_simulated:
		#print("play score = ", play.score)
	var roll = randi_range(0, 5)
	print("play score = ", list_of_plays_simulated[roll].score)
	physics_controller.PhysicsObjects_List[list_of_plays_simulated[0].player_index].Execute_Action_parameters(list_of_plays_simulated[roll].direction, list_of_plays_simulated[0].force_lerp)

func Select_Best_Piece_To_Play(_teamSide: int) -> int:
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
	
	#print("Step Size = ", step)
	
	for k in range(1, max_force_steps + 1):
		var force_lerp = float(k) / float(max_force_steps)

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

func Get_Random_Piece_Index() -> int:
	if current_TeamSide == TeamSide.HOME:
		return PhysicsObjects_HomeTeam_IndexList.pick_random()
	elif current_TeamSide == TeamSide.AWAY:
		return PhysicsObjects_AwayTeam_IndexList.pick_random()
	
	return -1
