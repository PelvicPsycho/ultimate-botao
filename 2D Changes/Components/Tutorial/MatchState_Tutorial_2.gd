extends Node
class_name MatchState_Tutorial_2

enum turn {HOME, AWAY}
signal turno_trocado(turno_atual: turn)

@export var physics_controller: CollisionResolution2D_Tutorial_2
@export var anunciador_tempo: float

@export var is_final_tutorial: bool

@onready var timer = $Timer
#const SplashScreen := preload("res://Componentes/MainMenu/start_menu_canvas_layer.tscn")
const TabMenu := preload("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn") 
const Tutorial_2 := preload("res://2D Changes/Components/Tutorial/Scenes/MatchScene2D_Tutorial_2.tscn") 

@export_group("Nodos")
@export var anunciador_ui: CanvasLayer
@export var pause_menu: PauseMenu_Tutorial

var allPieces: Array[PhysicsPlayer2D_Tutorial_2]
var selectedPiece: PhysicsPlayer2D_Tutorial_2
@export var homeTeam: Team

@export var audio_fez_gol: AudioStream

# Cache para otimização
var allBalls: Array[Node]
var efeitos_visuais_ativos: Dictionary = {}
var carta_usada_no_turno: bool = false
var currentTurn: turn
var jogadores: Array = [] 

# Contador de congelamento. Só descongela quando chegar a zero.
var freeze_level: int = 0

var game_started: bool = false
var game_paused: bool = false
var match_ended: bool = false

var game_initial_pause_ended: bool = false

var game_Tutorial_1_completed: bool = false



func _ready() -> void:
	print("_ready MatchState 0")
	
	add_to_group("MatchState2d_Tutorial")  
	loadMatch()

	allPieces.assign(get_tree().get_nodes_in_group("Players"))
	allBalls = get_tree().get_nodes_in_group("Balls")
	
	var goals = get_tree().get_nodes_in_group("Goals")
	for goal in goals:
		goal.gol.connect(onGoal)
		print("connect --------------")
		
	var jogadores_salvos: Array = GameState.jogadores
	
	var save_map = {}
	for j in jogadores_salvos:
		save_map[j.id_unico] = j
	
	print("_ready MatchState 1")
	
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

	print("_ready MatchState 2")
	# Chamar quando quiser ter uma pausa inicial
	# Select what team play first
	currentTurn = turn.HOME

func _process(_delta: float) -> void:
	_sincronizar_estado_congelamento()

func loadMatch():
	assignPieces()
	
	physics_controller.start_Collision_resulution(false, false, false)
	
	print("loadMatch")

func assignPieces():
	var homePlayers: Array[TeamPlayer] = homeTeam.mainSquad
	var homePieces = $PhysicsController/HomeTeam.get_children()
	
	print("homePlayers = ", homePlayers.size())
	
	for i in range(homePieces.size()):
		print("i = ", i)
		var piece = homePieces[i]
		var player = homePlayers[i]
		piece.team = homeTeam
		piece.playerInfo = player
		
		print("player = ", player)
		piece.loadPlayerInfo(player)
	
	physics_controller.all_physicObjects_loaded = true

func _on_partida_acabou() -> void:
	pause_menu.pode_abrir = false
	

func onGoal(isHome: bool) -> void:
	game_Tutorial_1_completed = true
	SoundMaster.play_sfx(audio_fez_gol)
	print("onGoal --------------")
	
	if game_Tutorial_1_completed:
		print("game_Tutorial_1_completed")
	
	endMatch()
	
	if is_final_tutorial:
		print("TabMenu --------------")
		#get_tree().call_deferred("change_scene_to_file", "res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")
		#get_tree().change_scene_to_file("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")
		#get_tree().change_scene_to_file("res://path_to_your_scene.tscn")
		timer.start()
		## 1. Load the packed scene
		#var next_scene_resource = load("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")
		## 2. Instance the scene into a node
		#var next_scene_instance = next_scene_resource.instantiate()
		## 3. Add it to the active SceneTree (This triggers _ready())
		#get_tree().root.add_child(next_scene_instance)
		## 4. Optional: Remove the old scene
		#queue_free()
	else:
		print("Tutorial_2 --------------")
		#get_tree().change_scene_to_file("res://2D Changes/Components/Tutorial/Scenes/MatchScene2D_Tutorial_2.tscn")
		get_tree().change_scene_to_packed(Tutorial_2)
		
		#var next_scene_resource = load("res://2D Changes/Components/Tutorial/Scenes/MatchScene2D_Tutorial_2.tscn")
		## 2. Instance the scene into a node
		#var next_scene_instance = next_scene_resource.instantiate()
		## 3. Add it to the active SceneTree (This triggers _ready())
		#get_tree().root.add_child(next_scene_instance)
		## 4. Optional: Remove the old scene
		#queue_free()


func onClickedPiece(piece: PhysicsPlayer2D_Tutorial_2) -> void:
	if carta_usada_no_turno:
		return 
	selectedPiece = piece
	piece.abrir_botoes_cartas()

func onTurnPlayed() -> void:
	congelar_jogo(true, 1)
	
	var parado_corretamente: bool = await waitAllStopped()
	if not parado_corretamente or not is_inside_tree():
		return
	
	congelar_jogo(false)

func _on_lance_acabou() -> void: 
	var alguma_peca_arrastada: bool = false
	var peca_arrastada: PhysicsPlayer2D_Tutorial_2 = null
	
	for piece in allPieces:
		if piece.is_dragging:
			alguma_peca_arrastada = true
			peca_arrastada = piece
			break
			
	if alguma_peca_arrastada and peca_arrastada != null:
		peca_arrastada.puxar_no_timeout()
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


func selectFirstTurn() -> void:
	for ball in allBalls:
		ball.lastTouch = null
		ball.firstTouch = null
	
	physics_controller.reset_last_touch_of_all_pieces()

	
func changeTurn() -> void:
	for piece in allPieces:
		if (currentTurn == turn.HOME and piece.team == homeTeam):
			piece.playerInfo_atual.processar_expiracao_de_buffs(piece.playerInfo)
	
	currentTurn = turn.HOME

	emit_signal("turno_trocado", currentTurn)
	
	for piece in allPieces:
		piece.canPlay = (currentTurn == turn.HOME) if piece.team == homeTeam else (currentTurn == turn.AWAY)

	for ball in allBalls:
		ball.lastTouch = null
		ball.firstTouch = null
	
	physics_controller.reset_last_touch_of_all_pieces()
	
	atualizar_cores_pecas()

	# 1. Congela o jogo pra ninguém chutar o botão fora de hora
	congelar_jogo(true, 1)
	#print("congelar_jogo")



# 4. Roda quando acabar a animação de entrada do contador de lances
func _continuar_troca_de_turno(active_team: Team) -> void:
	# O jogo já está congelado desde changeTurn().
	carta_usada_no_turno = false

func _on_anuncio_turno_fim() -> void:
	congelar_jogo(false)

func _on_anuncio_inicial_fim() -> void:
	congelar_jogo(false)


func _on_anuncio_text_livre_fim() -> void:
	congelar_jogo(false)
	print("_on_anuncio_text_livre_fim")

func _on_anuncio_match_start_end() -> void:
	game_initial_pause_ended = true
	#print("match_start animation ended")
	selectFirstTurn()

	atualizar_cores_pecas()

	
func forceTurn(target: turn) -> void:
	currentTurn = target

	emit_signal("turno_trocado", currentTurn)

	for ball in allBalls:
		ball.lastTouch = null
		ball.firstTouch = null
	
	physics_controller.reset_last_touch_of_all_pieces()
	
	atualizar_cores_pecas()
	
	for piece in allPieces:
		if piece.playerInfo_atual:
			piece.playerInfo_atual.processar_passagem_de_turno(piece.playerInfo)
		piece.canPlay = (currentTurn == turn.HOME) if piece.team == homeTeam else (currentTurn == turn.AWAY)
	
	carta_usada_no_turno = false

enum TurnType {ORIGINAL, SIMPLIFIED, INTERSPERSED, ORIGINAL_SHORT}
@onready var turnDecider: TurnType = TurnType.ORIGINAL_SHORT

func decideTurn() -> void:
	for piece in allPieces:
		if piece.playerInfo_atual:
			piece.playerInfo_atual.processar_expiracao_de_lance(piece.playerInfo)
	
	for ball in allBalls:
		match turnDecider:
			0:
				var lastTouch = ball.lastTouch
				if lastTouch == null:
					continue
				
				ball.lastTouch = null
				physics_controller.reset_last_touch_of_all_pieces()
				break
	changeTurn() 

func atualizar_cores_pecas() -> void:
	for p in allPieces:
		var deve_ativar: bool = true
		p.definir_estado_visual(deve_ativar)
		
func isCorrectSide(team: Team) -> bool:
	return (currentTurn == turn.HOME and team == homeTeam)

## Mostra a recompensa primeiro. Após coletar, abre o result_canvas
## para o jogador decidir o próximo passo (botão Next).
func endMatch():
	match_ended = true
	#var resultCanvas = $ResultCanvas
	
	congelar_jogo(true, 999999)
	
	#resultCanvas._show(winner, str(homeScore) + " X " + str(awayScore), true)

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
		#print("congelar_jogo - D")
		
func _sincronizar_estado_congelamento() -> void:
	var deve_congelar: bool = freeze_level > 0
	for piece in allPieces:
		piece.disabled = deve_congelar
	
	if deve_congelar:
		if game_paused == false:
			print("Game Paused = ", true)
		game_paused = true
	else:
		if game_paused == true:
			print("Game Paused = ", false)
		game_paused = false
		

func tentar_usar_carta(piece: PhysicsPlayer2D_Tutorial_2, carta: CardResource) -> void:
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

func _on_player_clicked_piece(Piece: PhysicsPlayer2D_Tutorial_2) -> void:
	if carta_usada_no_turno:
		return

func get_current_turn_int() -> int:
	if currentTurn == turn.HOME:
		return 0
	elif currentTurn == turn.AWAY:
		return 1
	
	return 0


func _on_timer_timeout() -> void:
	GameState.finished_tutorial = true
	get_tree().change_scene_to_file("res://Componentes/MainMenu/start_menu_canvas_layer.tscn")
