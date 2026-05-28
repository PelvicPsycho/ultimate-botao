extends Node2D
class_name Simulation_Test

@export var physics_controller: CollisionResolution2D_Simulation
@export var simulation_controller: SimulationController_Test

var PhysicsObjects_HomeTeam_IndexList: Array[int]
var PhysicsObjects_AwayTeam_IndexList: Array[int]
var PhysicsObjects_Ball_IndexList: Array[int]

enum TeamSide {HOME, AWAY}
var current_TeamSide: TeamSide

var time_to_IA_play: float = 5
var current_time: float = 4

@export var AI_Active: bool = false
var AI_CanRun: bool = false

func _ready() -> void:
	current_TeamSide = TeamSide.HOME

func _process(delta: float) -> void:
	current_time += delta
	
	if current_time >= time_to_IA_play and AI_Active and AI_CanRun:
		
		var index = GetCurrentPieceIndex()
		
		if index >= 0:
			print("IA play")
			simulation_controller.call_get_all_best_plays_rotation(index, current_TeamSide)
			
			# Change side
			if current_TeamSide == TeamSide.HOME:
				current_TeamSide = TeamSide.AWAY
			elif current_TeamSide == TeamSide.AWAY:
				current_TeamSide = TeamSide.HOME
		
		current_time = 0

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
		
		AI_CanRun = true
