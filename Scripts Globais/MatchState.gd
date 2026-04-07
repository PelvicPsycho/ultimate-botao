extends Node

enum turn {HOME, AWAY}
enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }

var modo_atual = ModoTiro.PUXAR

var allPieces: Array[Player]
var selectedPiece: Player

@export var homeTeam: Team
var homeScore: int
var homePlayers: Array[Player]
@export var awayTeam: Team
var awayScore: int
var awayPlayers: Array[Player]

var currentTurn: turn
var rallyCounter: int
var turnCounter: int = 0
var foulFlag: bool = false
var goalFlag: bool = false

@onready var label_home: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Home
@onready var label_away: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Away
@onready var timer = $MatchTimer

func _ready():
	selectFirstTurn()
	homeScore = 0
	awayScore = 0
	rallyCounter = 1
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	var nodes = get_tree().get_nodes_in_group("Players")
	allPieces.assign(nodes)
	var goals = get_tree().get_nodes_in_group("Goals")
	for goal in goals:
		goal.connect("gol", onGoal)
	for piece in allPieces:
		piece.connect("clickedPiece", onClickedPiece)
		piece.connect("turnPlayed", onTurnPlayed)
		if piece.team == homeTeam:
			homePlayers.append(piece)
			piece.canPlay = (currentTurn == turn.HOME)
		else:
			awayPlayers.append(piece)
			piece.canPlay = (currentTurn == turn.AWAY)
	_atualizar_placar()
	timer.partida_acabou.connect(_on_partida_acabou)
	timer.lance_acabou.connect(_on_lance_acabou)
	timer.iniciar_partida()
	timer.iniciar_lance(currentTurn)

func _atualizar_placar() -> void:
	if label_home:
		label_home.text = str(homeScore)

	if label_away:
		label_away.text = str(awayScore)

func _on_lance_acabou() -> void:
	changeTurn()

func _on_partida_acabou() -> void:
	timer.parar_tudo()
	endMatch(homeTeam.name if homeScore>awayScore else awayTeam.name if homeScore<awayScore else "ninguém")

func onGoal(isHome: bool):
	goalFlag = true
	#checa infração de bola no gol de primeira
	if rallyCounter == 1:
		foulFlag=true
		#return
	rallyCounter=1
	if isHome and !foulFlag:
		awayScore += 1
	elif !foulFlag:
		homeScore += 1
	if homeScore > 2 or awayScore > 2:
		if homeScore > awayScore:
			endMatch(homeTeam.name)
		else:
			endMatch(awayTeam.name)
	_atualizar_placar()

func onClickedPiece(piece: Player):
	selectedPiece = piece

func printState():
	print("turnCounter: ", turnCounter)
	print("rallyCounter: ", rallyCounter)
	print("goalFlag: ", goalFlag)
	print("foulFlag: ", foulFlag)
	print("homeScore: ", homeScore)
	print("awayScore: ", awayScore)
	print("current turn is ", homeTeam.name if currentTurn == turn.HOME else awayTeam.name)

func onTurnPlayed():
	for piece in allPieces:
		piece.disabled = true
	timer.pausar_lance()
	
	await get_tree().create_timer(1.0).timeout #FUTURAMENTE, ESPERAR AS PEÇAS PARAREM
	
	#await waitAllStopped()
	
	printState()
	for piece in allPieces:
		piece.disabled = false
	decideTurn()
	timer.retomar_lance()
	timer.resetar_barra_lance()

#Função para checar se todas a bola parou ( é um pouco ineficiente)
func waitAllStopped() -> void:
	const VELOCITY_THRESHOLD: float = 0.01
	var balls = get_tree().get_nodes_in_group("Balls")
	while true:
		await get_tree().physics_frame
		var all_stopped: bool = true
		for p in allPieces:
			print(p.name + " " + str(p.linear_velocity.length()))
			if p.linear_velocity.length() > VELOCITY_THRESHOLD or p.angular_velocity.length() > VELOCITY_THRESHOLD:
				all_stopped = false
				break
		for ball in balls:
			print(ball.name +" "+str(ball.linear_velocity.length()))
			if ball.linear_velocity.length() > VELOCITY_THRESHOLD or ball.angular_velocity.length() > VELOCITY_THRESHOLD:
				all_stopped = false
				break
		if all_stopped:
			break

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()

func selectFirstTurn():
	currentTurn = turn.AWAY if randi_range(0, 1) > 0 else turn.HOME

func changeTurn():
	currentTurn = turn.AWAY if currentTurn == turn.HOME else turn.HOME
	for piece in allPieces:
		piece.canPlay = !piece.canPlay
	turnCounter = 0
	timer.iniciar_lance(currentTurn)

# Chamado pelo gol_manager após a animação de gol.
# Força o turno para o time vitima e limpa todas as flags.
func forceTurn(target: turn) -> void:
	currentTurn = target
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	for piece in allPieces:
		if piece.team == homeTeam:
			piece.canPlay = (currentTurn == turn.HOME)
		else:
			piece.canPlay = (currentTurn == turn.AWAY)
	timer.iniciar_lance(currentTurn)

# -------------REGRAS DA POSSE-----------------------------
# Se o time do turno atual tiver tocado por ultimo na bola, mantem a posse
# Se o time que possui a posse tocar na bola mas tiver no seu terceiro turno consecutivo, troca
# Se o time do turno não encostar ou do time sem a posse tocar por ultimo, troca
# Se o time que possui a posse cometer uma infração(fazer gol no primeiro lance), troca
# ---------------------------------------------------------
func decideTurn():
	if goalFlag:
		return # Aguarda o gol_manager resolver o turno via forceTurn()
	var balls = get_tree().get_nodes_in_group("Balls")
	for ball in balls:
		var lastTouch = ball.lastTouch
		if lastTouch != null:
			rallyCounter+= 1
			if isCorrectSide(lastTouch.team) and turnCounter < 2:
				print("Ultimo a tocar: ", lastTouch.team.name, "\nTurn Counter: ", turnCounter)
				turnCounter+=1
				ball.lastTouch = null
				print("----------------------------------------------")
				return # Se o time do turno atual tiver tocado por ultimo na bola, mantem a posse
		if lastTouch != null and isCorrectSide(lastTouch.team) and turnCounter >= 2:
			print("TOCOU MAIS DE 3 VEZES")
		if lastTouch != null and !isCorrectSide(lastTouch.team):
			print("Ultimo a tocar: ", lastTouch.team.name)
	print("----------------------------------------------")
	changeTurn() # Senão troca

func isCorrectSide(team:Team) -> bool:
	return (currentTurn == turn.HOME and team == homeTeam) or (currentTurn == turn.AWAY and team == awayTeam)

# Chamar uma caixa de texto dizendo quem ganhou e um botão para reiniciar
func endMatch(winner: String):
	var resultCanvas = $ResultCanvas
	await get_tree().create_timer(3.0, true).timeout
	resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore))
