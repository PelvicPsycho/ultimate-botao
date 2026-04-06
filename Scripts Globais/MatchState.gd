extends Node

enum turn { HOME, AWAY }
enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }

var modo_atual = ModoTiro.PUXAR

var allPieces: Array[Player] = []
var selectedPiece: Player

@export var homeTeam: Team
var homeScore: int = 0
var homePlayers: Array[Player] = []

@export var awayTeam: Team
var awayScore: int = 0
var awayPlayers: Array[Player] = []

var currentTurn: turn
var turnCounter: int = 0
var foulFlag: bool = false
var goalFlag: bool = false
@onready var label_home: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Home
@onready var label_away: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Away
@onready var timer = $MatchTimer


func _ready() -> void:
	selectFirstTurn()

	homeScore = 0
	awayScore = 0
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
	print("⏰ Tempo do lance acabou.")
	changeTurn()
	timer.iniciar_lance(currentTurn)


func _on_partida_acabou() -> void:
	print("⏰ Fim da partida!")
	timer.parar_tudo()


func onTurnPlayed() -> void:
	for piece in allPieces:
		piece.disabled = true

	timer.pausar_lance()

	await get_tree().create_timer(1.0).timeout

	for piece in allPieces:
		piece.disabled = false

	print("Turno jogado, verificando posse...")
	decideTurn()

	timer.retomar_lance()
	timer.resetar_barra_lance()

func decideTurn() -> void:
	if goalFlag:
		return

	var balls = get_tree().get_nodes_in_group("ball")
	var tocou_correto = false

	for ball in balls:
		var lastTouch = ball.lastTouch
		if lastTouch != null and isCorrectSide(lastTouch.team) and turnCounter < 2 and !foulFlag:
			turnCounter += 1
			ball.lastTouch = null
			tocou_correto = true
			break
		else:
			ball.lastTouch = null

	if not tocou_correto:
		print("❌ Jogador errou a bola! Troca de turno.")
		changeTurn()


func changeTurn() -> void:
	if currentTurn == turn.HOME:
		currentTurn = turn.AWAY
	else:
		currentTurn = turn.HOME

	for piece in allPieces:
		piece.canPlay = !piece.canPlay

	turnCounter = 0
	timer.iniciar_lance(currentTurn)

	print("Turno atual: ", "HOME" if currentTurn == turn.HOME else "AWAY")


func onGoal(isHome: bool) -> void:
	goalFlag = true
	

	if isHome:
		awayScore += 1
	else:
		homeScore += 1

	_atualizar_placar()
	print("GOL! ", homeScore, " X ", awayScore)

func forceTurn(target: turn) -> void:
	currentTurn = target
	turnCounter = 0
	foulFlag = false
	goalFlag = false

	for piece in allPieces:
		piece.canPlay = (piece.team == homeTeam and currentTurn == turn.HOME) or (piece.team == awayTeam and currentTurn == turn.AWAY)

	timer.iniciar_lance(currentTurn)


func selectFirstTurn() -> void:
	currentTurn = turn.AWAY if randi_range(0, 1) > 0 else turn.HOME


func isCorrectSide(team: Team) -> bool:
	return (currentTurn == turn.HOME and team == homeTeam) or (currentTurn == turn.AWAY and team == awayTeam)


func onClickedPiece(piece: Player) -> void:
	selectedPiece = piece
	
