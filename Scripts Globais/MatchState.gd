extends Node

enum turn {HOME, AWAY}
enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }

var modo_atual = ModoTiro.PUXAR

var allPieces: Array[Player]
var selectedPiece: Player
@export var anunciador_ui: CanvasLayer
@export var homeTeam: Team
var homeScore: int
var homePlayers: Array[Player]
@export var awayTeam: Team
var awayScore: int
var awayPlayers: Array[Player]
@export var vermelho_active : ShaderMaterial = preload("res://Componentes/PlayerGradientes/TimeVermelho.tres")
@export var vermelho_inactive : ShaderMaterial =preload("res://Componentes/PlayerGradientes/TimeVermelhoDesactive.tres")
@export var azul_active : ShaderMaterial= preload("res://Componentes/PlayerGradientes/TimeAzul.tres")
@export var azul_inactive : ShaderMaterial = preload("res://Componentes/PlayerGradientes/TimeAzulDesactive.tres")

var currentTurn: turn
var rallyCounter: int
var turnCounter: int = 0
var foulFlag: bool = false
var goalFlag: bool = false

@export_group("Sons do Árbitro")
@export var audio_mudou_turno: AudioStream
@export var audio_perdeu_turno: AudioStream

#@onready var label_home: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Home
#@onready var label_away: Label = $CanvasLayer/VSplitContainer/HBoxContainer/Label_Away
@onready var timer = $MatchTimer

var gol_de_ouro = false

# Contador de congelamento. Só descongela quando chegar a zero.
var freeze_level: int = 0

func _ready():
	%MatchUI.UI_start(homeTeam,awayTeam)
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
		if goal.team == goal.TeamSide.HOME:
			goal.changeColor(homeTeam.id)
		else:
			goal.changeColor(awayTeam.id)
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
	
	timer.time_label_changed.connect(%MatchUI._atualizar_label_partida)
	
	timer._atualizar_barra_lance.connect(%MatchUI._atualizar_barra_lance)
	timer.resetar_barra_lance.connect(%MatchUI.resetar_barra_lance)
	#timer._atualizar_cor_barra.connect(%MatchUI._atualizar_cor_barra)
	
	timer.iniciar_partida()
	timer.iniciar_lance(currentTurn)
	disparar_anuncio_com_pausa(tr("BEGIN"), 100, 2.0, Color.DARK_RED)
	var nome = homeTeam.name if currentTurn == turn.HOME else awayTeam.name
	get_tree().create_timer(2).timeout.connect(disparar_anuncio_com_pausa.bind(tr("TURN_OF")+"\n" + nome, 80, 1.5), CONNECT_ONE_SHOT)
	atualizar_cores_pecas()
	
func _atualizar_placar() -> void:
	#if label_home:
		#label_home.text = str(homeScore)
	#if label_away:
		#label_away.text = str(awayScore)
	%MatchUI.placar_esq.text = str(homeScore)
	%MatchUI.placar_dir.text = str(awayScore)

func _on_lance_acabou() -> void: 
	var alguma_peca_arrastada = false
	var peca_arrastada
	for piece in allPieces: #verifica se alguma peca esta sendo arrastada
		if piece.is_dragging == true:
			alguma_peca_arrastada = true
			peca_arrastada = piece
			break
	if alguma_peca_arrastada:
		timer.lance_rodando = true
		peca_arrastada.puxar_no_timeout()
	else:
		changeTurn()

func _on_partida_acabou() -> void:
	timer.parar_tudo()
	#print("FIM DO TEMPO!")
	
	if homeScore == awayScore:
		gol_de_ouro = true
	else:
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
		if gol_de_ouro:
			endMatch(awayTeam.name)
	elif !foulFlag:
		homeScore += 1
		if gol_de_ouro:
			endMatch(homeTeam.name)
	if homeScore > 2 or awayScore > 2:
		#print("REGRA DA CLEMÊNCIA!")
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

func onTurnPlayed() -> void:
	congelar_jogo(true)
	#await get_tree().create_timer(1.0).timeout #FUTURAMENTE, ESPERAR AS PEÇAS PARAREM
	var parado_corretamente = await waitAllStopped()
	if not parado_corretamente or not is_inside_tree():
		return
#	printState()
	congelar_jogo(false)
	decideTurn()
	timer.iniciar_lance(currentTurn)

# Função para checar se todas as peças e a bola realmente estabilizaram.
# Exige vários physics frames seguidos em repouso para evitar falso positivo.
# Retorna false se foi abortado (ex: cena reiniciada durante o await).
func waitAllStopped() -> bool:
	const LINEAR_THRESHOLD: float = 0.01
	const ANGULAR_THRESHOLD: float = 0.01
	const FRAMES_ESTAVEIS: int = 8
	const FRAMES_DE_GRACA: int = 2

	var frames_estaveis := 0
	var frames_passados := 0
	var balls = get_tree().get_nodes_in_group("Balls")

	while frames_estaveis < FRAMES_ESTAVEIS:
		if not is_inside_tree():
			return false
		await get_tree().physics_frame #crashou o jogo usando o pause + reiniciar partida
		frames_passados += 1

		# Dá alguns frames para o impulso inicial e as primeiras colisões acontecerem.
		if frames_passados <= FRAMES_DE_GRACA:
			continue

		var todos_parados := true

		for piece in allPieces:
			if (
				piece.linear_velocity.length() > LINEAR_THRESHOLD
				or piece.angular_velocity.length() > ANGULAR_THRESHOLD
				or not piece.sleeping
			):
				todos_parados = false
				break

		if todos_parados:
			for ball in balls:
				if (
					ball.linear_velocity.length() > LINEAR_THRESHOLD
					or ball.angular_velocity.length() > ANGULAR_THRESHOLD
					or not ball.sleeping
				):
					todos_parados = false
					break

		if todos_parados:
			frames_estaveis += 1
		else:
			frames_estaveis = 0

	return true

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()

func selectFirstTurn():
	currentTurn = turn.AWAY if randi_range(0, 1) > 0 else turn.HOME
	if currentTurn == turn.HOME:
		%MatchUI.colorir_turno(homeTeam,turnCounter) 
	else: %MatchUI.colorir_turno(awayTeam,turnCounter)
	

func changeTurn():
	currentTurn = turn.AWAY if currentTurn == turn.HOME else turn.HOME
	for piece in allPieces:
		piece.canPlay = !piece.canPlay
	turnCounter = 0
	atualizar_cores_pecas()
	if currentTurn == turn.HOME:
		%MatchUI.colorir_turno(homeTeam,turnCounter)
	else: %MatchUI.colorir_turno(awayTeam,turnCounter)
	var nome = homeTeam.name if currentTurn == turn.HOME else awayTeam.name
	disparar_anuncio_com_pausa(tr("TURN_OF")+"\n" + nome, 80, 1.5)
	atualizar_cores_pecas()

# Chamado pelo gol_manager após a animação de gol.
# Força o turno para o time vitima e limpa as flags de lance.
# NOTA: não limpamos goalFlag aqui; isso é feito em decideTurn()
# para garantir que onTurnPlayed() saiba que houve gol mesmo que
# acorde depois de forceTurn() ter sido chamado.
func forceTurn(target: turn) -> void:
	currentTurn = target
	turnCounter = 0
	foulFlag = false
	for piece in allPieces:
		if piece.team == homeTeam:
			piece.canPlay = (currentTurn == turn.HOME)
		else:
			piece.canPlay = (currentTurn == turn.AWAY)
	if currentTurn == turn.HOME:
		%MatchUI.colorir_turno(homeTeam,turnCounter)
	else: %MatchUI.colorir_turno(awayTeam,turnCounter)
#	timer.pausado = true
	timer.iniciar_lance(currentTurn)
	var nome = homeTeam.name if currentTurn == turn.HOME else awayTeam.name
	disparar_anuncio_com_pausa(tr("TURN_OF")+"\n" + nome, 80, 1.5)

# -------------REGRAS DA POSSE-----------------------------
# Se o time do turno atual tiver tocado por ultimo na bola, mantem a posse
# Se o time que possui a posse tocar na bola mas tiver no seu terceiro turno consecutivo, troca
# Se o time do turno não encostar ou do time sem a posse tocar por ultimo, troca
# Se o time que possui a posse cometer uma infração(fazer gol no primeiro lance), troca
# ---------------------------------------------------------
func decideTurn():
	var por_erro = true
	if goalFlag:
		# O gol_manager já chamou forceTurn() durante o anúncio de gol.
		# Apenas limpamos a flag para o próximo lance e saímos.
		goalFlag = false
		return
	var balls = get_tree().get_nodes_in_group("Balls")
	for ball in balls:
		var lastTouch = ball.lastTouch
		if lastTouch != null:
			rallyCounter+= 1
			if isCorrectSide(lastTouch.team) and turnCounter < 2:
				#print("Ultimo a tocar: ", lastTouch.team.name, "\nTurn Counter: ", turnCounter)
				turnCounter+=1
				ball.lastTouch = null
				#print("----------------------------------------------")
				if currentTurn == turn.HOME:
					%MatchUI.colorir_turno(homeTeam,turnCounter)
				else: %MatchUI.colorir_turno(awayTeam,turnCounter)
				disparar_anuncio_com_pausa(tr("KEEP_GOING")+"!", 60, 0.5, Color.YELLOW)
				return # Se o time do turno atual tiver tocado por ultimo na bola, mantem a posse
		if lastTouch != null and isCorrectSide(lastTouch.team) and turnCounter >= 2:
			#print("TOCOU MAIS DE 3 VEZES")
			por_erro = false
		#if lastTouch != null and !isCorrectSide(lastTouch.team):
			#print("Ultimo a tocar: ", lastTouch.team.name)
	#print("----------------------------------------------")
	if por_erro:
		SoundMaster.play_sfx(audio_perdeu_turno, 1.0, 0.0)
	else:
		SoundMaster.play_sfx(audio_mudou_turno, 1.0, 0.0)

	changeTurn() # Senão troca
	
func atualizar_cores_pecas() -> void:
	var home_turn := (currentTurn == turn.HOME)

	for p in allPieces:
		var pode := (p.team == homeTeam) if home_turn else (p.team == awayTeam)

		# aplicar material correspondente
		if p.team == homeTeam:
			p.aplicar_material(azul_active if pode else azul_inactive)
		else:
			p.aplicar_material(vermelho_active if pode else vermelho_inactive)

		p.canPlay = pode
func isCorrectSide(team:Team) -> bool:
	return (currentTurn == turn.HOME and team == homeTeam) or (currentTurn == turn.AWAY and team == awayTeam)

# Chamar uma caixa de texto dizendo quem ganhou e um botão para reiniciar
func endMatch(winner: String):
	var resultCanvas = $ResultCanvas
	await get_tree().create_timer(3.0, true).timeout
	resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore))

func congelar_jogo(congelar: bool, tempo: float = -1.0) -> void:
	if congelar:
		freeze_level += 1
	else:
		freeze_level = max(0, freeze_level - 1)
	_sincronizar_estado_congelamento()
	
	# Se um tempo foi especificado, agenda o descongelamento automático.
	if congelar and tempo > 0.0:
		get_tree().create_timer(tempo).timeout.connect(_descongelar_auto, CONNECT_ONE_SHOT)

func _descongelar_auto() -> void:
	# Proteção caso o nó tenha sido destruído antes do timer disparar.
	if is_instance_valid(self) and is_inside_tree():
		congelar_jogo(false)

func _sincronizar_estado_congelamento() -> void:
	var deve_congelar: bool= freeze_level > 0
	if deve_congelar:
		timer.pausar_lance()
	else:
		timer.retomar_lance()
	for piece in allPieces:
		piece.disabled = deve_congelar

func disparar_anuncio_com_pausa(texto: String, tamanho: int, tempo: float, cor: Color = Color.WHITE):
	#Trava as peças e o lance
	congelar_jogo(true, tempo + 0.2)
	
	#Mostra o texto
	anunciador_ui.mostrar_evento(texto, tamanho, tempo, cor)
	
	# Usamos um callable local para garantir que CADA chamada desta função
	# seja pareada com exatamente um descongelamento, mesmo que anúncios
	# sejam disparados em sequência antes do anterior terminar.
	var descongelar = func():
		congelar_jogo(false)
		# Se for uma troca de turno, você pode chamar o reset da barra aqui
		timer.call_resetar_barra_lance()
	
	anunciador_ui.anuncio_encerrado.connect(descongelar, CONNECT_ONE_SHOT)
