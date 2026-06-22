extends Node
class_name MatchState_AI

enum turn {HOME, AWAY}
signal turno_trocado(turno_atual: turn)

@export var physics_controller: CollisionResolution2D

@export var show_play_simulation_result: bool
@export var show_play_simulation_result_index: int

@export var IA_Active: bool
@export var IA_Contr: IA_Controller

@export var gradient_background_TextureRect: TextureRect
var gradient_texture: GradientTexture2D

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

var game_started: bool = false
var game_paused: bool = false



func _ready() -> void:
	add_to_group("MatchState2d")  
	loadMatch()
	SoundMaster.play_bgm(audio_murmurio_fundo, "loop")
	%MatchUI.UI_start(homeTeam, awayTeam)
	
	gradient_texture = gradient_background_TextureRect.texture as GradientTexture2D
	
	selectFirstTurn()
	
	allPieces.assign(get_tree().get_nodes_in_group("Players"))
	allBalls = get_tree().get_nodes_in_group("Balls")
	
	var goals = get_tree().get_nodes_in_group("Goals")
	for goal in goals:
		goal.gol.connect(onGoal)
		
	var jogadores_salvos: Array = GameState.jogadores
	
	var save_map = {}
	for j in jogadores_salvos:
		save_map[j.id_unico] = j

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
		var res_atual = piece.playerInfo_atual
		var id_da_peca = piece.playerInfo.id_unico
		
		print("Verificando Peça: ", res_atual.nome, " [ID: ", id_da_peca, "]")
		
		
		if save_map.has(id_da_peca):
			var res_save = save_map[id_da_peca]
			res_atual.slotsUpgrates = res_save.slotsUpgrates.duplicate()
			res_atual.mao_cartas = res_save.mao_cartas.duplicate()
			print("  💾 [SAVE] Dados carregados para ", res_atual.nome)
		
			piece.playerInfo_atual.aplicar_passivas()
		
		else:
			if not res_atual.mao_cartas.is_empty():
				
				res_atual.slotsUpgrates = res_atual.mao_cartas.duplicate()
				print("  ❌ [ERRO] ID   '", id_da_peca, "' Usando as cartas da mão.")
				
			else:
				print("  ❌ [ERRO] ID '", id_da_peca, "' sem dados no Save e mão vazia no Editor.")
		
		# 4. Sempre aplica as passivas (seja do save ou do fallback da mão)
		res_atual.aplicar_passivas()
	
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
	
	match timer.tipo_do_timer:
		timer.TimerType.TIMER:
			%MatchUI.progressBar.max_value = timer.tempo_maximo_partida
			%MatchUI.shotsProgressBarHome.max_value = timer.tempo_maximo_lance
			%MatchUI.shotsProgressBarAway.max_value = timer.tempo_maximo_lance
			timer.partida_acabou.connect(_on_partida_acabou)
			timer.time_label_changed.connect(%MatchUI._atualizar_label_partida)
			timer.lance_label_changed.connect(%MatchUI._atualizar_label_lance)
			timer.lance_acabou.connect(_on_lance_acabou)
			timer.iniciar_partida(currentTurn == turn.HOME)
			timer.iniciar_lance(currentTurn)
		timer.TimerType.SHOTS:
			%MatchUI.progressBar.max_value = timer.totalShots
			timer.partida_acabou.connect(_on_partida_acabou)
			timer.time_label_changed.connect(%MatchUI._atualizar_label_partida)
			timer.iniciar_partida()
		timer.TimerType.CHESS:
			%MatchUI.progressBar.max_value = timer.homeTimeMax
			%MatchUI.shotsProgressBarHome.max_value = timer.homeTimeMax
			%MatchUI.shotsProgressBarAway.max_value = timer.homeTimeMax
			timer.partida_acabou.connect(_on_partida_acabou)
			timer.time_label_changed.connect(%MatchUI._atualizar_label_partida)
			timer.lance_label_changed.connect(%MatchUI._atualizar_label_lance)
			timer.punishTeam.connect(_on_punish_team)
			timer.iniciar_partida(currentTurn == turn.HOME)
	
	disparar_anuncio_com_pausa(tr("BEGIN"), 100, 2.0, homeTeam.cor if currentTurn == turn.HOME else awayTeam.cor)
	get_tree().create_timer(2.0).timeout.connect(_on_begin_timeout, CONNECT_ONE_SHOT)
	atualizar_cores_pecas()
	
func _on_begin_timeout():
	var nome = homeTeam.name if currentTurn == turn.HOME else awayTeam.name
	disparar_anuncio_com_pausa.bind(tr("TURN_OF")+"\n" + nome, 80, 1.5)
	timer.partida_rodando = true

func loadMatch():
	if not PvPManager.isPvpMatch:
		IA_Active = true
		homeTeam = CupManager.myTeam
		awayTeam = CupManager.currentCompetitor
	else:
		IA_Active = false
		homeTeam = PvPManager.teams[0]
		awayTeam = PvPManager.teams[1]
	
	homeScore = 0
	awayScore = 0
	rallyCounter = 1
	turnCounter = 0
	foulFlag = false
	goalFlag = false
	assignPieces()
	
	physics_controller.start_Collision_resulution(IA_Active, show_play_simulation_result, show_play_simulation_result_index)

func assignPieces():
	var homePlayers: Array[TeamPlayer] = homeTeam.mainSquad
	var awayPlayers: Array[TeamPlayer] = awayTeam.mainSquad
	var homePieces = $PhysicsController/HomeTeam.get_children()
	var awayPieces = $PhysicsController/AwayTeam.get_children()
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
	
	physics_controller.all_physicObjects_loaded = true

func _atualizar_placar() -> void:
	%MatchUI.atualizar_placar(homeScore, awayScore)

func _on_punish_team(isHome: bool):
	_aplicar_punicao_chess(isHome)
	$"Gol_Manager(Temporario)".anunciar_gol_pt2(isHome)
	timer.resetTimer(isHome)

func _aplicar_punicao_chess(isHome: bool) -> void:
	# No CHESS, timeout precisa sempre virar penalidade no placar.
	goalFlag = false
	rallyCounter = 1
	foulFlag = false

	if isHome:
		awayScore += 1
		if gol_de_ouro:
			endMatch(awayTeam.name)
	else:
		homeScore += 1
		if gol_de_ouro:
			endMatch(homeTeam.name)

	if homeScore > 2 or awayScore > 2:
		var vencedor = homeTeam.name if homeScore > awayScore else awayTeam.name
		endMatch(vencedor)

	_atualizar_placar()

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
	
	if timer.tipo_do_timer == 1:
		timer.resetAllChessTimers()
	_atualizar_placar()

func onClickedPiece(piece: PhysicsPlayer2D) -> void:
	if carta_usada_no_turno:
		return 
	selectedPiece = piece
	piece.abrir_botoes_cartas()

func onTurnPlayed() -> void:
	congelar_jogo(true)
	if timer.tipo_do_timer == 1:
		timer.pauseChessTimer()
	elif timer.tipo_do_timer == 0:
		timer.pauseOngoingPlayFlag()
	if timer.tipo_do_timer == timer.TimerType.CHESS:
		if currentTurn == turn.HOME and timer.homeTimeRemaining <= 10.0:
			timer.addTime(true)
		elif timer.awayTimeRemaining <= 10.0:
			timer.addTime(false)
	var parado_corretamente: bool = await waitAllStopped()
	if not parado_corretamente or not is_inside_tree():
		return
		
	congelar_jogo(false)
	if timer.tipo_do_timer == 1:
		timer.resumeChessTimer()
	elif timer.tipo_do_timer == 0:
		timer.resumeOngoingPlayFlag()
	if timer.tipo_do_timer == timer.TimerType.SHOTS:
		timer.countShot()
	if timer.tipo_do_timer == timer.TimerType.TIMER:
		timer.iniciar_lance(currentTurn)
	decideTurn()

func _on_lance_acabou() -> void: 
	var alguma_peca_arrastada: bool = false
	var peca_arrastada: PhysicsPlayer2D = null
	
	for piece in allPieces:
		if piece.is_dragging:
			alguma_peca_arrastada = true
			peca_arrastada = piece
			break
			
	if alguma_peca_arrastada and peca_arrastada != null:
		timer.lance_rodando = true
		peca_arrastada.puxar_no_timeout()
		#
		#if peca_arrastada.vetor_arrasto_atual.length_squared() <= 25.0:
			#changeTurn()
	else:
		changeTurn()

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

# Gradient
func change_gradient_background_TextureRect_Offsets() -> void:
	if currentTurn == turn.HOME:
		gradient_texture.gradient.set_offset(0, 0.75)
		gradient_texture.gradient.set_offset(1, 1.00)
	elif currentTurn == turn.AWAY:
		gradient_texture.gradient.set_offset(0, 0.00)
		gradient_texture.gradient.set_offset(1, 0.25)
	
	gradient_background_TextureRect.texture = gradient_texture

func change_gradient_background_TextureRect_Colors() -> void:
	# Get colors from team info
	var homeTeam_color = homeTeam.cor
	var awayTeam_color = awayTeam.cor
	
	# Set transparency 
	homeTeam_color.a = 0.3
	awayTeam_color.a = 0.3
	
	# Update gradient with new colors
	gradient_texture.gradient.set_color(0, homeTeam_color)
	gradient_texture.gradient.set_color(1, awayTeam_color)
	
	# Update background TextureRect
	gradient_background_TextureRect.texture = gradient_texture

func selectFirstTurn() -> void:
	currentTurn = turn.AWAY if randi_range(0, 1) > 0 else turn.HOME
	change_gradient_background_TextureRect_Colors()
	change_gradient_background_TextureRect_Offsets()
	
	for ball in allBalls:
		ball.lastTouch = null
		ball.firstTouch = null
	
	physics_controller.reset_last_touch_of_all_pieces()
	var active_team = homeTeam if currentTurn == turn.HOME else awayTeam
	
	if IA_Active and IA_Contr != null:
		IA_Contr.SetCurrentTeamSide(currentTurn)
		
	%MatchUI.colorir_turno(active_team, turnCounter) 
	
func changeTurn() -> void:
	for piece in allPieces:
		if (currentTurn == turn.HOME and piece.team == homeTeam) or (currentTurn == turn.AWAY and piece.team == awayTeam):
			piece.playerInfo_atual.processar_expiracao_de_buffs(piece.playerInfo)
	currentTurn = turn.AWAY if currentTurn == turn.HOME else turn.HOME
	change_gradient_background_TextureRect_Colors()
	change_gradient_background_TextureRect_Offsets()
	emit_signal("turno_trocado", currentTurn)
	for piece in allPieces:
		piece.canPlay = (currentTurn == turn.HOME) if piece.team == homeTeam else (currentTurn == turn.AWAY)
	turnCounter = 0
	foulFlag = false
	rallyCounter = 2
	for ball in allBalls:
		ball.lastTouch = null
		ball.firstTouch = null
	
	physics_controller.reset_last_touch_of_all_pieces()
	
	atualizar_cores_pecas()
	
	var active_team = homeTeam if currentTurn == turn.HOME else awayTeam
	
	if IA_Active and IA_Contr != null:
		IA_Contr.SetCurrentTeamSide(currentTurn)
		
	%MatchUI.colorir_turno(active_team, turnCounter)
	if timer.tipo_do_timer == timer.TimerType.CHESS:
		timer.isHomeTurn = (currentTurn == turn.HOME)
		
	if timer.tipo_do_timer == timer.TimerType.TIMER:
		timer.iniciar_lance(currentTurn)
		
	disparar_anuncio_com_pausa(tr("TURN_OF")+"\n" + active_team.name, 80, 1.5)
	carta_usada_no_turno = false

func forceTurn(target: turn) -> void:
	currentTurn = target
	change_gradient_background_TextureRect_Colors()
	change_gradient_background_TextureRect_Offsets()
	emit_signal("turno_trocado", currentTurn)
	turnCounter = 0
	foulFlag = false
	rallyCounter = 2
	for ball in allBalls:
		ball.lastTouch = null
		ball.firstTouch = null
	
	physics_controller.reset_last_touch_of_all_pieces()
	
	atualizar_cores_pecas()
	
	for piece in allPieces:
		if piece.playerInfo_atual:
			piece.playerInfo_atual.processar_passagem_de_turno(piece.playerInfo)
		piece.canPlay = (currentTurn == turn.HOME) if piece.team == homeTeam else (currentTurn == turn.AWAY)
			
	var active_team = homeTeam if currentTurn == turn.HOME else awayTeam
	
	if IA_Active and IA_Contr != null:
		IA_Contr.SetCurrentTeamSide(currentTurn)
		
	%MatchUI.colorir_turno(active_team, turnCounter)
	if timer.tipo_do_timer == timer.TimerType.CHESS:
		timer.isHomeTurn = (currentTurn == turn.HOME)
	if timer.tipo_do_timer == timer.TimerType.TIMER:
		timer.iniciar_lance(currentTurn)
	disparar_anuncio_com_pausa(tr("TURN_OF")+"\n" + active_team.name, 80, 1.5)
	carta_usada_no_turno = false

enum TurnType {ORIGINAL, SIMPLIFIED, INTERSPERSED, ORIGINAL_SHORT}
@onready var turnDecider: TurnType = TurnType.ORIGINAL

func decideTurn() -> void:
	var por_erro: bool = true
	if goalFlag:
		goalFlag = false
		return
		
	for ball in allBalls:
		match turnDecider:
			0:
				var lastTouch = ball.lastTouch
				if lastTouch == null:
					continue
				
				rallyCounter += 1
				var toque_time_correto: bool = isCorrectSide(lastTouch.team)
				if toque_time_correto and turnCounter < 2:
					turnCounter += 1
					if currentTurn == turn.HOME:
						%MatchUI.colorir_turno(homeTeam,turnCounter)
					else: 
						%MatchUI.colorir_turno(awayTeam,turnCounter)
					
					if turnCounter < 2:
						disparar_anuncio_com_pausa(tr("KEEP_GOING")+"!", 60, 0.5, Color.YELLOW)
					else:
						disparar_anuncio_com_pausa(tr("LAST_SHOT")+"!", 60, 0.5, Color.YELLOW)
					
					if IA_Active and IA_Contr != null:
						IA_Contr.SetCurrentTeamSide(currentTurn)
					
					ball.lastTouch = null
					physics_controller.reset_last_touch_of_all_pieces()
					return

				# Se o time correto tocou com turnCounter >= 2, segue para troca com som "mudou".
				if toque_time_correto and turnCounter >= 2:
					por_erro = false
				ball.lastTouch = null
				physics_controller.reset_last_touch_of_all_pieces()
				break
			1:
				var firstTouch = ball.firstTouch
				if firstTouch == null:
					continue

				rallyCounter += 1
				var toque_time_correto_first: bool = isCorrectSide(firstTouch.team)
				if toque_time_correto_first and turnCounter < 2:
					turnCounter += 1
					if currentTurn == turn.HOME:
						%MatchUI.colorir_turno(homeTeam,turnCounter)
					else: 
						%MatchUI.colorir_turno(awayTeam,turnCounter)

					if turnCounter < 2:
						disparar_anuncio_com_pausa(tr("KEEP_GOING")+"!", 60, 0.5, Color.YELLOW)
					else:
						disparar_anuncio_com_pausa(tr("LAST_SHOT")+"!", 60, 0.5, Color.YELLOW)
					
					if IA_Active and IA_Contr != null:
						IA_Contr.SetCurrentTeamSide(currentTurn)
						
					ball.firstTouch = null
					physics_controller.reset_last_touch_of_all_pieces()
					return

				if toque_time_correto_first and turnCounter >= 2:
					por_erro = false
				ball.firstTouch = null
				physics_controller.reset_last_touch_of_all_pieces()
				break
			2:
				pass
			3:
				var lastTouch = ball.lastTouch
				if lastTouch == null:
					continue

				rallyCounter += 1
				var toque_time_correto: bool = isCorrectSide(lastTouch.team)
				if toque_time_correto and turnCounter < 1:
					turnCounter += 1
					if currentTurn == turn.HOME:
						%MatchUI.colorir_turno(homeTeam,turnCounter)
					else: 
						%MatchUI.colorir_turno(awayTeam,turnCounter)

					if turnCounter < 1:
						disparar_anuncio_com_pausa(tr("KEEP_GOING")+"!", 60, 0.5, Color.YELLOW)
					else:
						disparar_anuncio_com_pausa(tr("LAST_SHOT")+"!", 60, 0.5, Color.YELLOW)
					
					if IA_Active and IA_Contr != null:
						IA_Contr.SetCurrentTeamSide(currentTurn)
						
					ball.lastTouch = null
					physics_controller.reset_last_touch_of_all_pieces()
					return

				# Se o time correto tocou com turnCounter >= 2, segue para troca com som "mudou".
				if toque_time_correto and turnCounter >= 1:
					por_erro = false
				ball.lastTouch = null
				physics_controller.reset_last_touch_of_all_pieces()
				break

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
		if cena_recompensa_torneio and !PvPManager.isPvpMatch:
			var tela = cena_recompensa_torneio.instantiate()
			tela.anchors_preset = Control.PRESET_FULL_RECT
			%MatchUI.add_child(tela)
			tela.iniciar_tela_de_torneio(CupManager.currentCup)
			await tela.recompensa_coletada
	else:
		if cena_recompensa_partida and !PvPManager.isPvpMatch:
			var tela = cena_recompensa_partida.instantiate()
			tela.anchors_preset = Control.PRESET_FULL_RECT
			%MatchUI.add_child(tela)
			tela.iniciar_tela_de_recompensa(awayTeam)
			await tela.recompensa_coletada
	
	# ── Depois da recompensa, abre o result_canvas ──
	
	resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore), true)

func congelar_jogo(congelar: bool, tempo: float = -1.0) -> void:
	game_paused = congelar
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

func get_current_turn_int() -> int:
	if currentTurn == turn.HOME:
		return 0
	elif currentTurn == turn.AWAY:
		return 1
	
	return 0
