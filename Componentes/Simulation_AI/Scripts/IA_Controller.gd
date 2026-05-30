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

var new_play: Play
var current_index: int

func _ready() -> void:
	current_TeamSide = TeamSide.HOME

func _process(delta: float) -> void:
	if AI_Active and AI_CanRun:
		
		current_index = GetCurrentPieceIndex()
		AI_NewPlay_Waiting = false
		
		if current_index >= 0:
			print("IA play")
			new_play = simulation_controller.call_get_all_best_plays_rotation(current_index, TeamSide.AWAY)
			AI_CanRun = false
			current_time = 0
			AI_NewPlay_Waiting = true
	
	if AI_NewPlay_Waiting:
		current_time += delta
		if current_time >= time_to_IA_play:
			physics_controller.PhysicsObjects_List[current_index].Execute_Action_parameters(new_play.direction, new_play.force_lerp)
			AI_NewPlay_Waiting = false


func GetCurrentPieceIndex() -> int:
	if current_TeamSide == TeamSide.HOME:
		return PhysicsObjects_HomeTeam_IndexList.pick_random()
	elif current_TeamSide == TeamSide.AWAY:
		return PhysicsObjects_AwayTeam_IndexList.pick_random()
	
	return -1

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
	AI_Active = true

func SetCurrentTeamSide(_teamSide: int) -> void:
	current_TeamSide = _teamSide
	if current_TeamSide == TeamSide.AWAY:
		AI_CanRun = true
