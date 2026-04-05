extends Node

enum turn {HOME, AWAY}
enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }

# 🔴 Configurações de Jogo
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
var turnCounter: int
var foulFlag: bool = false
var goalFlag: bool = false

# 🔵 Lógica do Script Velho Adaptada
@export var tempo_maximo_lance: float = 10.0
@export var caminho_label_lance: NodePath
#onready var label_lance: Label =$CanvasLayer/Label_Lance
@export var caminho_label_home: NodePath
@export var caminho_label_away: NodePath
@onready var label_partida: Label = $CanvasLayer/VSplitContainer/Label_Tempo
@export var tempo_maximo_partida: float = 150 # 2:30
var tempo_partida_restante: float = 0.0
var partida_rodando: bool = false
@onready var progressBar_Lance = $CanvasLayer/TextureProgressBar_Lance
@export var textura_home: Texture2D
@export var textura_away: Texture2D
var lance_rodando: bool = false
@onready var label_home: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Home
@onready var label_away: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Away
var tempo_restante: float = 0.0
var rodando: bool = false
var pausado: bool = false

func _ready():
	selectFirstTurn()
	homeScore = 0
	awayScore = 0
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	progressBar_Lance.value= 50
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
	tempo_partida_restante = tempo_maximo_partida
	partida_rodando = true
	_atualizar_label_partida()
	_atualizar_placar()

	# Inicia o tempo logo que o jogo começa
	iniciar_lance()
	#rint("Label Lance: ", label_lance)
	print("Caminho configurado: ", caminho_label_lance)
	#if label_lance == null:
	#	print("❌ ERRO: Label não encontrado! Verifique o NodePath no Inspector.")
	#else:
	#	print("✅ Label encontrado e pronto.")
		
func _atualizar_placar() -> void:
	if label_home:
		label_home.text = str(homeScore)
	if label_away:
		label_away.text = str(awayScore)
		
func _process(delta: float) -> void:
	if not rodando or goalFlag:
		return

	# Se a física está rolando (peças movendo), o tempo não conta
	if pausado:
		if _partida_parou():
			pausado = false
			print("✅ Física parou, retomando timer.")
		else:
			# Remova este print depois que funcionar, ele serve para ver se está travado aqui
			# print("⏳ Aguardando peças pararem...") 
			return

	tempo_restante -= delta
	if progressBar_Lance:
		progressBar_Lance.value = tempo_restante
	#_atualizar_label()
	if partida_rodando:
		tempo_partida_restante -= delta

	if tempo_partida_restante <= 0.0:
		tempo_partida_restante = 0.0
		partida_rodando = false
		_atualizar_label_partida()
		fim_de_partida()
		return

	_atualizar_label_partida()
	if tempo_restante <= 0.0:
		tempo_restante = 0.0
		if progressBar_Lance:
			progressBar_Lance.value = 0.0
	#	_atualizar_label()
		print("⏰ Tempo esgotado! Trocando turno.")
		changeTurn()
		iniciar_lance()

# 🟢 Funções de Controle do Timer
func iniciar_lance() -> void:
	tempo_restante = tempo_maximo_lance
	rodando = true
	pausado = false

	if progressBar_Lance:
		progressBar_Lance.min_value = 0
		progressBar_Lance.max_value = tempo_maximo_lance
		progressBar_Lance.value = tempo_maximo_lance

	atualizar_barra_turno()
func pausar_lance() -> void:
	pausado = true

func _partida_parou() -> bool:
	var limite_velocidade = 0.2
	# Verifica se todas as peças pararam de se mover
	for p in allPieces:
		if p is RigidBody3D:
			if not p.sleeping and p.linear_velocity.length() > limite_velocidade:
				return false
	# Verifica se a bola parou de se mover
	var balls = get_tree().get_nodes_in_group("ball")
	for ball in balls:
		if ball is RigidBody3D:
			if not ball.sleeping and ball.linear_velocity.length() > limite_velocidade:
				return false
	return true
func _atualizar_label_partida() -> void:
	if label_partida == null:
		return

	var minutos := int(tempo_partida_restante) / 60
	var segundos := int(tempo_partida_restante) % 60
	label_partida.text = "%02d:%02d" % [minutos, segundos]
#func _atualizar_label() -> void:
#	if label_lance == null:
#		return
#	var minutos := int(tempo_restante) / 60
#	var segundos := int(tempo_restante) % 60
	#label_lance.text = "%02d:%02d" % [minutos, segundos]

# 🟡 Lógica de Turnos e Eventos
func atualizar_barra_turno() -> void:
	if progressBar_Lance == null:
		return

	if currentTurn == turn.HOME:
		progressBar_Lance.self_modulate = Color(0.2, 0.5, 1.0) # azul
	else:
		progressBar_Lance.self_modulate = Color(1.0, 0.3, 0.3) # vermelho
func onTurnPlayed():
	for piece in allPieces:
		piece.disabled = true

	# Pausa o timer enquanto as peças batem e se movem
	pausar_lance()

	await get_tree().create_timer(1.0).timeout

	for piece in allPieces:
		piece.disabled = false

	print("Turno jogado, verificando posse...")
	decideTurn()
	# Reinicia o tempo para o próximo lance (mesmo time ou troca)
	iniciar_lance()
func fim_de_partida() -> void:
	print("⏰ Fim da partida!")
	rodando = false
	pausado = false
func decideTurn():
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

func changeTurn():
	if currentTurn == turn.HOME:
		currentTurn = turn.AWAY
	else:
		currentTurn = turn.HOME

	for piece in allPieces:
		piece.canPlay = !piece.canPlay

	turnCounter = 0
	atualizar_barra_turno()

	print("Turno atual: ", "HOME" if currentTurn == turn.HOME else "AWAY")

func onGoal(isHome: bool):
	goalFlag = true
	rodando = false # Para o timer no gol
	if isHome:
		awayScore += 1
	else:
		homeScore += 1
	print("GOL! ", homeScore, " X ", awayScore)
	_atualizar_placar() 
func forceTurn(target: turn) -> void:
	currentTurn = target
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	for piece in allPieces:
		piece.canPlay = (piece.team == homeTeam and currentTurn == turn.HOME) or (piece.team == awayTeam and currentTurn == turn.AWAY)
	iniciar_lance()

func selectFirstTurn():
	currentTurn = turn.AWAY if randi_range(0,1) > 0 else turn.HOME

func isCorrectSide(team: Team) -> bool:
	return (currentTurn == turn.HOME and team == homeTeam) or (currentTurn == turn.AWAY and team == awayTeam)

func onClickedPiece(piece: Player):
	selectedPiece = piece
