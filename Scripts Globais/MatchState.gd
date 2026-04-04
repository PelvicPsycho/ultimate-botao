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
var turnCounter: int
var foulFlag: bool = false
var goalFlag: bool = false

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
			piece.canPlay = true if currentTurn == turn.HOME else false
		else:
			awayPlayers.append(piece)
			piece.canPlay = true if currentTurn == turn.AWAY else false

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
	print("GOL! ", homeScore, " X ", awayScore)

func onClickedPiece(piece: Player):
	selectedPiece = piece
	print("Selected Piece: ", str(selectedPiece))

func onTurnPlayed():
	for piece in allPieces:
		piece.disabled = true
	await get_tree().create_timer(2.0).timeout #FUTURAMENTE, ESPERAR AS PEÇAS PARAREM
	#await waitAllStopped()
	for piece in allPieces:
		piece.disabled = false
	print("turno jogado")
	decideTurn()

#Função para checar se todas a bola parou ( é um pouco ineficiente)
func waitAllStopped() -> void:
	const VELOCITY_THRESHOLD: float = 0.5
	var balls = get_tree().get_nodes_in_group("Balls")
	while true:
		await get_tree().physics_frame
		var all_stopped: bool = true
		for ball in balls:
			if ball.linear_velocity.length() > VELOCITY_THRESHOLD or ball.angular_velocity.length() > VELOCITY_THRESHOLD:
				all_stopped = false
				break
		if all_stopped:
			break

func _on_button_pressed() -> void:
	# Alterna entre os modos (por enquanto 0 e 1, o 2 deixaremos pronto)
	modo_atual = (modo_atual + 1) % 3 
	
	var texto_botao = ""
	match modo_atual:
		ModoTiro.PUXAR:
			texto_botao = "Modo: Puxar"
		ModoTiro.EMPURRAR:
			texto_botao = "Modo: Empurrar"
		ModoTiro.MODO_3:
			texto_botao = "Modo: Carregar"
			
	$CanvasLayer/Button.text = texto_botao
	
	# Avisa todas as peças do jogo qual é o novo modo
	get_tree().call_group("pecas", "set_modo_tiro", modo_atual)

func _on_button_puxar_pressed() -> void:
	_on_button_pressed()

func _on_botao_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()

func selectFirstTurn():
	var randomNum = randi_range(0,1)
	if randomNum>0:
		currentTurn = turn.AWAY
	else:
		currentTurn = turn.HOME
	print("current turn is ", homeTeam.name if currentTurn == turn.HOME else awayTeam.name)

func changeTurn():
	if currentTurn == turn.HOME:
		currentTurn = turn.AWAY
	else:
		currentTurn = turn.HOME
	for piece in allPieces:
		piece.canPlay = !piece.canPlay
	print("current turn is ", homeTeam.name if currentTurn == turn.HOME else awayTeam.name)

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
	print("Turno forçado para ", homeTeam.name if currentTurn == turn.HOME else awayTeam.name)

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
		if lastTouch != null and isCorrectSide(lastTouch.team) and turnCounter < 2 and !foulFlag:
			
			#conta rally
			rallyCounter+= 1
			
			turnCounter+=1
			ball.lastTouch = null
			return # Se o time do turno atual tiver tocado por ultimo na bola, mantem a posse
	changeTurn() # Senão troca

func isCorrectSide(team:Team) -> bool:
	if currentTurn == turn.HOME:
		if team == homeTeam:
			return true
	else:
		if team == awayTeam:
			return true
	return false

# Chamar uma caixa de texto dizendo quem ganhou e um botão para reiniciar
func endMatch(winner: String):
	var resultCanvas = $ResultCanvas
	await get_tree().create_timer(3.0, true).timeout
	resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore))
