extends Node2D
class_name IA_Controller

@export var physics_controller: CollisionResolution2D
@export var simulation_controller: SimulationController

var PhysicsObjects_HomeTeam_IndexList: Array[int]
var PhysicsObjects_AwayTeam_IndexList: Array[int]
var PhysicsObjects_Ball_IndexList: Array[int]

enum TeamSide {HOME, AWAY}
var current_TeamSide: TeamSide

var time_to_IA_play: float = 1
var current_time: float = 0

var AI_Active: bool = false
var AI_CanRun: bool = false

var AI_NewPlay_Waiting: bool = false

var current_index: int

var list_of_all_plays_simulated: Array[Play]

var list_of_plays_to_simulate: Array[Play]

#func _ready() -> void:
	#current_TeamSide = TeamSide.HOME
	
	#for i in range(physics_controller.num_threads):
		#var new_list_of_plays: Array[Play]
		
		
		
#func _process(delta: float) -> void:
	#if AI_Active and AI_CanRun:
		#current_index = GetCurrentPieceIndex()
		#AI_NewPlay_Waiting = false
		#
		#if current_index >= 0:
			#print("IA play")
			#list_of_all_plays_simulated.clear()
			##new_play = simulation_controller.call_get_all_best_plays_rotation(current_index, TeamSide.AWAY)
			##execute_and_score_plays_with_Threads(list_of_all_plays_to_simulate: Array[Play])
			#AI_CanRun = false
			#current_time = 0
			#AI_NewPlay_Waiting = true
	#
	#if AI_NewPlay_Waiting:
		#current_time += delta
		#if current_time >= time_to_IA_play:
			##physics_controller.PhysicsObjects_List[current_index].Execute_Action_parameters(new_play.direction, new_play.force_lerp)
			#AI_NewPlay_Waiting = false


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
	print("num_plays = ", num_plays)
	print("step = ", step)
	
	list_of_plays_to_simulate.clear()
	
	for k in range(1, simulation_controller.max_force_steps + 1):
		var force_lerp = float(k) / float(simulation_controller.max_force_steps)

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

func Set_Piece_Lists() -> void:
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
	AI_Active = true

func Set_Current_TeamSide(_teamSide: int) -> void:
	current_TeamSide = _teamSide as TeamSide
	if current_TeamSide == TeamSide.AWAY:
		AI_CanRun = true
