extends MatchState_Tutorial
class_name MatchState_Training

@onready var SpawnPoints: Array = $SpawnPoints.get_children()
@onready var player = $PhysicsController/HomeTeam/HomeTeam_P5
@onready var ball = $PhysicsController/Balls/Ball2D_Tutorial
@export var arenaIndex = 0

var goalsScored = 0

signal goalScored(arena:int)

func _ready() -> void:
	add_to_group("MatchState2d_Tutorial")

	# setup mínimo
	allPieces.assign(get_tree().get_nodes_in_group("Players"))
	allBalls = get_tree().get_nodes_in_group("Balls")
	loadMatch()

func loadMatch() -> void:
	assignPieces()
	physics_controller.start_Collision_resulution(false, false, false)

func assignPieces() -> void:
	var homePlayers: Array[TeamPlayer] = homeTeam.mainSquad
	var homePieces = $PhysicsController/HomeTeam.get_children()
	var max_count := mini(homePieces.size(), homePlayers.size())

	for i in range(max_count):
		var piece = homePieces[i]
		var squad_player = homePlayers[i]
		if squad_player == null:
			continue
		piece.team = homeTeam
		piece.playerInfo = squad_player
		piece.loadPlayerInfo(squad_player)

	physics_controller.all_physicObjects_loaded = true

func pickPlayerSpawn():
	var pickedSP = SpawnPoints.pick_random()
	#player.global_position = pickedSP.global_position
	return pickedSP
	
func pickBallSpawn():
	var pickedSP = SpawnPoints.pick_random()
	return pickedSP
	#ball.global_position = pickedSP.global_position
	#ball.Set_Current_Velocity(Vector2.ZERO)

func _on_goal_2d_gol(_isHome):
	goalsScored += 1
	print("goooooooooala")
	goalScored.emit(arenaIndex)
