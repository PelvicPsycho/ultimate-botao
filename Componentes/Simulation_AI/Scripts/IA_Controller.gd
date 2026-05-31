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


func _ready() -> void:
	current_TeamSide = TeamSide.HOME

func _process(delta: float) -> void:
	if AI_Active and AI_CanRun:
		AI_NewPlay_Waiting = false
		AI_CanRun = false
		current_time = 0
		
		var piece_list: Array[int]
		if current_TeamSide == TeamSide.HOME:
			piece_list = PhysicsObjects_HomeTeam_IndexList
		else:
			piece_list = PhysicsObjects_AwayTeam_IndexList
		
		if piece_list.size() > 0:
			print("IA play — testing ", piece_list.size(), " pieces")
			new_play = simulation_controller.get_best_play_for_team(current_TeamSide, piece_list)
			AI_NewPlay_Waiting = true
	
	if AI_NewPlay_Waiting:
		current_time += delta
		if current_time >= time_to_IA_play:
			physics_controller.PhysicsObjects_List[new_play.player_index].Execute_Action_parameters(new_play.direction, new_play.force_lerp)
			AI_NewPlay_Waiting = false


## Removido: GetCurrentPieceIndex não é mais necessário;
## o get_best_play_for_team testa todas as peças do time.

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
