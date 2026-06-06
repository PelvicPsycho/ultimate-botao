extends Node
class_name MatchState

enum turn {HOME, AWAY}
enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }

var modo_atual: ModoTiro = ModoTiro.PUXAR
signal turno_trocado(turno_atual: turn)
#@export var IA_Contr: IA_Controller

var allPieces: Array[PhysicsPlayer2D]
var selectedPiece: PhysicsPlayer2D
@export var anunciador_ui: CanvasLayer
var homeTeam: Team
var homeScore: int
var awayTeam: Team
var awayScore: int

# Cache para otimização
var allBalls: Array[Node]
var efeitos_visuais_ativos: Dictionary = {}
var carta_usada_no_turno: bool = false
var currentTurn: turn
var rallyCounter: int = 1
var turnCounter: int = 0
var foulFlag: bool = false
var goalFlag: bool = false
var jogadores: Array = [] 
@export_group("Sons do Árbitro")
@export var audio_mudou_turno: AudioStream
@export var audio_perdeu_turno: AudioStream
@export_group("Telas de Recompensa")
@export var cena_recompensa_partida: PackedScene
@export var cena_recompensa_torneio: PackedScene

@onready var timer = $MatchTimer
var gol_de_ouro: bool = false

# Contador de congelamento. Só descongela quando chegar a zero.
var freeze_level: int = 0

@export var audio_murmurio_fundo: AudioStream

func _ready() -> void:
	add_to_group("MatchState2d")  
	loadMatch()
	SoundMaster.play_bgm(audio_murmurio_fundo, "loop")
	%MatchUI.UI_start(homeTeam, awayTeam)
	selectFirstTurn()
	
	allPieces.assign(get_tree().get_nodes_in_group("Players"))
	allBalls = get_tree().get_nodes_in_group("Balls")
	
	var goals = get_tree().get_nodes_in_group("Goals")
	for goal in goals:
		goal.gol.connect(onGoal)
		
	var jogadores_salvos: Array = GameState.jogadores

	for piece in allPieces:
		var info := -1
		for i in jogadores_salvos.size():
			var j = jogadores_salvos[i]
			if j.nome == piece.playerInfo.nome:
				info = i
				break

		if info != -1:
			piece.playerInfo.slotsUpgrates = jogadores_salvos[info].slotsUpgrates.duplicate()
			piece.playerInfo_atual.slotsUpgrates = jogadores_salvos[info].slotsUpgrates.duplicate()

			#print("Cartas carregadas para ", piece.playerInfo.nome)
			#for c in piece.playerInfo.slotsUpgrates:
				#print("  - ", (c.resource_path if c else "Vazio"))
		
			piece.playerInfo_atual.aplicar_passivas()
	# CONEXÕES PADRÃO
		if not piece.clickedPiece.is_connected(_on_player_clicked_piece):
			piece.clickedPiece.connect(_on_player_clicked_piece)
			
		piece.turnPlayed.connect(onTurnPlayed)
		turno_trocado.connect(piece._no_turno_trocado)
	# DISTRIBUIÇÃO ENTRE EQUIPES
		if piece.team == homeTeam:
			piece.canPlay = (currentTurn == turn.HOME)
		else:
			piece.canPlay = (currentTurn == turn.AWAY)
	_atualizar_placar()
	
	timer.partida_acabou.connect(_on_partida_acabou)
	timer.time_label_changed.connect(%MatchUI._atualizar_label_partida)	
	timer.iniciar_partida()
	
	disparar_anuncio_com_pausa(tr("BEGIN"), 100, 2.0, homeTeam.cor if currentTurn == turn.HOME else awayTeam.cor)
	var nome = homeTeam.name if currentTurn == turn.HOME else awayTeam.name
	get_tree().create_timer(2.0).timeout.connect(disparar_anuncio_com_pausa.bind(tr("TURN_OF")+"\n" + nome, 80, 1.5), CONNECT_ONE_SHOT)
	atualizar_cores_pecas()
	
func loadMatch():
	homeTeam = CupManager.myTeam
	awayTeam = CupManager.currentCompetitor
	homeScore = 0
	awayScore = 0
	rallyCounter = 1
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	assignPieces()

func assignPieces():
	var homePlayers: Array[TeamPlayer] = homeTeam.mainSquad
	var awayPlayers: Array[TeamPlayer] = awayTeam.mainSquad
	var homePieces = $PhysicsObjects_Group/HomeTeam.get_children()
	var awayPieces = $PhysicsObjects_Group/AwayTeam.get_children()
	for i in range(homePieces.size()):
		var piece = homePieces[i]
		var player = homePlayers[i]
		piece.team = homeTeam
		piece.playerInfo = player
		piece.loadPlayerInfo(player)

	for i in range(awayPieces.size()):
		var piece = awayPieces[i]
		var player = awayPlayers[i]
		piece.team = awayTeam
		piece.playerInfo = player
		piece.loadPlayerInfo(player)

func _atualizar_placar() -> void:
	%MatchUI.atualizar_placar(homeScore, awayScore)

func _on_partida_acabou() -> void:
	timer.parar_tudo()
	if homeScore == awayScore:
		disparar_anuncio_com_pausa(tr("GOLDEN_GOAL"), 80, 1.5, Color.YELLOW)
		gol_de_ouro = true
	else:
		var vencedor = homeTeam.name if homeScore > awayScore else awayTeam.name
		endMatch(vencedor)

func onGoal(isHome: bool) -> void:
	goalFlag = true
	if rallyCounter == 1:
		foulFlag = true
	
	rallyCounter = 1
	if isHome and not foulFlag:
		awayScore += 1
		if gol_de_ouro: endMatch(awayTeam.name)
	elif not foulFlag:
		homeScore += 1
		if gol_de_ouro: endMatch(homeTeam.name)
		
	if homeScore > 2 or awayScore > 2:
		var vencedor = homeTeam.name if homeScore > awayScore else awayTeam.name
		endMatch(vencedor)
		
	_atualizar_placar()

func onClickedPiece(piece: PhysicsPlayer2D) -> void:
	selectedPiece = piece
	piece.abrir_botoes_cartas()

func onTurnPlayed() -> void:
	congelar_jogo(true)
	timer.rodando_lance()
	var parado_corretamente: bool = await waitAllStopped()
	if not parado_corretamente or not is_inside_tree():
		return
		
	congelar_jogo(false)
	timer.acabando_lance()
	decideTurn()

func waitAllStopped() -> bool:
	const LINEAR_THRESHOLD_SQ: float = 0.0001
	const ANGULAR_THRESHOLD_SQ: float = 0.0001
	const FRAMES_ESTAVEIS: int = 8
	const FRAMES_DE_GRACA: int = 2

	var frames_estaveis: int = 0
	var frames_passados: int = 0

	while frames_estaveis < FRAMES_ESTAVEIS:
		if not is_inside_tree():
			return false
			
		await get_tree().physics_frame
		frames_passados += 1
	
		if frames_passados <= FRAMES_DE_GRACA:
			continue

		var todos_parados: bool = true

		for piece in allPieces:
			if (
				piece.current_velocity.length_squared() > LINEAR_THRESHOLD_SQ
			):
				todos_parados = false
				break

		if todos_parados:
			for ball in allBalls:
				if (
					ball.current_velocity.length_squared() > LINEAR_THRESHOLD_SQ
				):
					todos_parados = false
					break

		if todos_parados:
			frames_estaveis += 1
		else:
			frames_estaveis = 0

	return true

func selectFirstTurn() -> void:
	currentTurn = turn.AWAY if randi_range(0, 1) > 0 else turn.HOME
	for ball in allBalls:
		ball.lastTouch = null
	var active_team = homeTeam if currentTurn == turn.HOME else awayTeam
	#IA_Contr.SetCurrentTeamSide(currentTurn)
	%MatchUI.colorir_turno(active_team, turnCounter) 
	
func changeTurn() -> void:
	for piece in allPieces:
		if (currentTurn == turn.HOME and piece.team == homeTeam) or (currentTurn == turn.AWAY and piece.team == awayTeam):
			piece.playerInfo_atual.processar_expiracao_de_buffs(piece.playerInfo)
	currentTurn = turn.AWAY if currentTurn == turn.HOME else turn.HOME
	emit_signal("turno_trocado", currentTurn)
	for piece in allPieces:
		piece.canPlay = (currentTurn == turn.HOME) if piece.team == homeTeam else (currentTurn == turn.AWAY)
	turnCounter = 0
	for ball in allBalls:
		ball.lastTouch = null
	atualizar_cores_pecas()
	
	var active_team = homeTeam if currentTurn == turn.HOME else awayTeam
	#IA_Contr.SetCurrentTeamSide(currentTurn)
	%MatchUI.colorir_turno(active_team, turnCounter)
	disparar_anuncio_com_pausa(tr("TURN_OF")+"\n" + active_team.name, 80, 1.5)
	carta_usada_no_turno = false

func forceTurn(target: turn) -> void:
	currentTurn = target
	emit_signal("turno_trocado", currentTurn)
	turnCounter = 0
	foulFlag = false
	for ball in allBalls:
		ball.lastTouch = null
	atualizar_cores_pecas()
	
	for piece in allPieces:
		if piece.playerInfo_atual:
			piece.playerInfo_atual.processar_passagem_de_turno(piece.playerInfo)
		piece.canPlay = (currentTurn == turn.HOME) if piece.team == homeTeam else (currentTurn == turn.AWAY)
			
	var active_team = homeTeam if currentTurn == turn.HOME else awayTeam
	#IA_Contr.SetCurrentTeamSide(currentTurn)
	%MatchUI.colorir_turno(active_team, turnCounter)
	disparar_anuncio_com_pausa(tr("TURN_OF")+"\n" + active_team.name, 80, 1.5)
	carta_usada_no_turno = false

func decideTurn() -> void:
	var por_erro: bool = true
	if goalFlag:
		goalFlag = false
		return
		
	for ball in allBalls:
		var lastTouch = ball.lastTouch
		if lastTouch != null:
			rallyCounter += 1
			if isCorrectSide(lastTouch.team) and turnCounter < 2:
				turnCounter += 1
				ball.lastTouch = null
				
				if currentTurn == turn.HOME:
					%MatchUI.colorir_turno(homeTeam,turnCounter)
				else: 
					%MatchUI.colorir_turno(awayTeam,turnCounter)
				
				if turnCounter < 2:
					disparar_anuncio_com_pausa(tr("KEEP_GOING")+"!", 60, 0.5, Color.YELLOW)
				else:
					disparar_anuncio_com_pausa(tr("LAST_SHOT")+"!", 60, 0.5, Color.YELLOW)
				
				#IA_Contr.SetCurrentTeamSide(currentTurn)
				return 
				
			if lastTouch != null and isCorrectSide(lastTouch.team) and turnCounter >= 2:
				por_erro = false

	if por_erro:
		SoundMaster.play_sfx(audio_perdeu_turno, 1.0, 0.0)
	else:
		SoundMaster.play_sfx(audio_mudou_turno, 1.0, 0.0)

	changeTurn() 
	
func atualizar_cores_pecas() -> void:
	var e_turno_home: bool = (currentTurn == turn.HOME)
	for p in allPieces:
		var deve_ativar: bool = (p.team == homeTeam) if e_turno_home else (p.team == awayTeam)
		p.definir_estado_visual(deve_ativar)
		
func isCorrectSide(team: Team) -> bool:
	return (currentTurn == turn.HOME and team == homeTeam) or (currentTurn == turn.AWAY and team == awayTeam)

## Mostra a recompensa primeiro. Após coletar, abre o result_canvas
## para o jogador decidir o próximo passo (botão Next).
func endMatch(winner: String):
	var resultCanvas = $ResultCanvas
	var jogador_venceu := winner == homeTeam.name
	
	if not jogador_venceu:
		await get_tree().create_timer(3.0, true).timeout
		resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore), false)
		return
	
	# ── Jogador venceu: recompensa primeiro ──
	if CupManager.isFinal:
		if cena_recompensa_torneio:
			var tela = cena_recompensa_torneio.instantiate()
			tela.anchors_preset = Control.PRESET_FULL_RECT
			%MatchUI.add_child(tela)
			tela.iniciar_tela_de_torneio(CupManager.currentCup)
			await tela.recompensa_coletada
	else:
		if cena_recompensa_partida:
			var tela = cena_recompensa_partida.instantiate()
			tela.anchors_preset = Control.PRESET_FULL_RECT
			%MatchUI.add_child(tela)
			tela.iniciar_tela_de_recompensa(awayTeam)
			await tela.recompensa_coletada
	
	# ── Depois da recompensa, abre o result_canvas ──
	
	resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore), true)

func congelar_jogo(congelar: bool, tempo: float = -1.0) -> void:
	if congelar:
		freeze_level += 1
	else:
		freeze_level = max(0, freeze_level - 1)
	_sincronizar_estado_congelamento()
	
	if congelar and tempo > 0.0:
		get_tree().create_timer(tempo).timeout.connect(_descongelar_auto, CONNECT_ONE_SHOT)

func _descongelar_auto() -> void:
	if is_instance_valid(self) and is_inside_tree():
		congelar_jogo(false)
func _sincronizar_estado_congelamento() -> void:
	var deve_congelar: bool = freeze_level > 0
	for piece in allPieces:
		piece.disabled = deve_congelar
func disparar_anuncio_com_pausa(texto: String, tamanho: int, tempo: float, cor: Color = Color.WHITE) -> void:
	congelar_jogo(true, tempo + 0.2)
	anunciador_ui.mostrar_evento(texto, tamanho, tempo, cor)
	
	var descongelar = func():
		congelar_jogo(false)
	
	anunciador_ui.anuncio_encerrado.connect(descongelar, CONNECT_ONE_SHOT)

func tentar_usar_carta(piece: PhysicsPlayer2D, carta: CardResource) -> void:
	if carta_usada_no_turno:
		return
	if piece == null or carta == null:
		print("Erro: peça ou carta inválida.")
		return
	if piece.playerInfo_atual.PA < carta.custo_energia:
		print("PA insuficiente! Precisa de ", carta.custo_energia, " PA, mas tem apenas ", piece.playerInfo_atual.PA)
		return
	
	piece.playerInfo_atual.aplicar_buff(carta)
	piece.animar_efeito_por_carta(carta) 
	carta_usada_no_turno = true

func _on_player_clicked_piece(Piece: PhysicsPlayer2D) -> void:
	if carta_usada_no_turno:
		return
		
	#var carta = %MatchUI.obter_carta_selecionada()
	#
	#if carta != null:
		#print("è diferente de null")
		#Piece.playerInfo_atual.aplicar_buff(carta)
		#carta_usada_no_turno = true
		#%MatchUI.consumir_carta_selecionada()
