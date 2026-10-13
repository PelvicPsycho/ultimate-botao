extends MatchState_AI
class_name MatchStateAIPlus1

@export var playerTeam: Team
@export var obstacleTeam: Team
@export var simulation: int = 0

func _ready() -> void:
	loadMatch()
	updateLabel()
	currentTurn = turn.HOME
	allPieces.assign(get_tree().get_nodes_in_group("Players"))
	for piece in allPieces:
		if piece.team == homeTeam:
			piece.canPlay = (currentTurn == turn.HOME)
		else:
			piece.canPlay = (currentTurn == turn.AWAY)

func loadMatch():
	awayTeam = obstacleTeam
	homeTeam = playerTeam
	
	homeScore = 0
	awayScore = 0
	rallyCounter = 1
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	assignPieces()
	respawn()
	
	physics_controller.start_Collision_resulution(false, false, false)

func assignPieces():
	var homePlayers: Array[TeamPlayer] = playerTeam.mainSquad
	var homePieces = $PhysicsController/HomeTeam.get_children()
	var awayPlayers: Array[TeamPlayer] = obstacleTeam.mainSquad
	var awayPieces = $PhysicsController/AwayTeam.get_children()
	
	#print("homePlayers = ", homePlayers.size())
	
	for i in range(homePieces.size()):
		#print("i = ", i)
		var piece = homePieces[i]
		var player = homePlayers[i]
		piece.team = homeTeam
		piece.playerInfo = player
		
		#print("player = ", player)
		piece.loadPlayerInfo(player)
	for i in range(awayPieces.size()):
		#print("i = ", i)
		var piece = awayPieces[i]
		var player = awayPlayers[i]
		piece.team = awayTeam
		piece.playerInfo = player
		
		#print("player = ", player)
		piece.loadPlayerInfo(player)
	
	physics_controller.all_physicObjects_loaded = true

func _process(_delta: float) -> void:
	pass

func _on_goal_2d_gol(isHome):
	respawn()

func respawn():
	var pSpawnPoints: Array = $PlayerSpawnPoints.get_children()
	var oSpawnPoints: Array = $ObstacleSpawnPoints.get_children()
	
	var homePieces = $PhysicsController/HomeTeam.get_children()
	var awayPieces = $PhysicsController/AwayTeam.get_children()
	
	var pickedSpawn
	
	for piece in homePieces:
		pickedSpawn = pSpawnPoints.pick_random()
		piece.Set_Current_Velocity(Vector2.ZERO)
		piece.global_position = pickedSpawn.global_position
		pSpawnPoints.remove_at(pSpawnPoints.find(pickedSpawn))
	
	for piece in awayPieces:
		pickedSpawn = oSpawnPoints.pick_random()
		piece.Set_Current_Velocity(Vector2.ZERO)
		piece.global_position = pickedSpawn.global_position
		oSpawnPoints.remove_at(oSpawnPoints.find(pickedSpawn))
	
	var ball = $PhysicsController/Balls/Ball2d
	var centerPoint = $PhysicsController/Pitch/Pitch_Middle_Point
	ball.Set_Current_Velocity(Vector2.ZERO)
	ball.global_position = centerPoint.global_position

func _on_home_team_p_1_turn_played():
	congelar_jogo(true, 3)
	var parado_corretamente: bool = await waitAllStopped()
	if not parado_corretamente or not is_inside_tree():
		return

func _sincronizar_estado_congelamento() -> void:
	var deve_congelar: bool = freeze_level > 0
	for piece in allPieces:
		piece.disabled = deve_congelar
	
	if deve_congelar:
		#if game_paused == false:
			#print("Game Paused = ", true)
		game_paused = true
	else:
		#if game_paused == true:
			#print("Game Paused = ", false)
		game_paused = false
		
func updateLabel(arena:int = 0, episode: int = 0, step:int = 0, goals:int = 0, selfGoals:int = 0):
	#var label = $CanvasLayer/MarginContainer/Label
	#label.text = "Arena: %d    Episode: %d    Step: %d    Goals: %d    Own Goals: %d" % [arena, episode, step, goals, selfGoals]
	print(Time.get_time_string_from_system())
	print("Arena: %d    Episode: %d    Step: %d    Goals: %d    Own Goals: %d" % [arena, episode, step, goals, selfGoals])
