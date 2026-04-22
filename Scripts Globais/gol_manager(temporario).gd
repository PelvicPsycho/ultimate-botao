extends Node3D

var todas_pecas: Array[Player] = []
var posicoes_iniciais_pecas: Dictionary = {}
var posicao_inicial_bola: Vector3
@export var tempo_anuncio_gol: float = 2
# CanvasLayer e Label criados por código para não precisar alterar a cena manualmente
var canvas_layer: CanvasLayer
var label_gol: Label
@export var anunciadorui: CanvasLayer
@export var match_state: Node3D

# Variável para referenciar o seu MatchState (assumindo que ele seja um Autoload ou esteja na cena)
#@onready var match_state = $".."

func _ready() -> void:
	# Aguarda um frame para garantir que os outros nós terminaram o _ready
	await get_tree().process_frame
	
	if not match_state:
		match_state = get_tree().root.get_node("MatchScene")
		
	# ---------------------------------------------------------
	# CORREÇÃO 1: Conexão de sinais padrão Godot 4 (Callable)
	# ---------------------------------------------------------
	var goals = get_tree().get_nodes_in_group("Goals")
	for goal in goals:
		# Usa a referência direta do sinal 'gol' em vez de string
		goal.gol.connect(anunciar_gol_e_resetar_campo)
		
	# ---------------------------------------------------------
	# CORREÇÃO 2: Cast seguro de Array de Nodes para Array de Player
	# ---------------------------------------------------------
	todas_pecas.clear() # Limpa por precaução
	var nodes_players = get_tree().get_nodes_in_group("Players")
	for node in nodes_players:
		if node is Player:
			todas_pecas.append(node as Player)
	
	# 1. Salvar as posições iniciais das peças
	for peca in todas_pecas:
		posicoes_iniciais_pecas[peca] = peca.global_transform
		
	# 2. Salvar posição inicial da bola (para reposicioná-la junto com as peças)
	var balls = get_tree().get_nodes_in_group("Balls")
	if balls.size() > 0:
		posicao_inicial_bola = balls[0].global_position
		

func anunciar_gol_e_resetar_campo(isHome: bool):
	# Trava as interações para nenhum jogador clicar nas peças durante a comemoração
	match_state.congelar_jogo(true)
	
	#checa se foi falta o gol
	if !match_state.foulFlag:
		
		# Dispara a UI
		anunciadorui.mostrar_evento(tr("GOAL"), 120, tempo_anuncio_gol, match_state.homeTeam.cor if !isHome else match_state.awayTeam.cor)
		
	# Delay de segundos (tempo_anuncio_gol)
	get_tree().create_timer(tempo_anuncio_gol).timeout.connect(anunciar_gol_pt2.bind(isHome))


func anunciar_gol_pt2(isHome):
		# Reseta e esconde o Label
		# Reposicionar as peças para as Transforms originais
	for peca in todas_pecas:
		peca.global_transform = posicoes_iniciais_pecas[peca]
		# MUITO IMPORTANTE: Zerar velocidades para não continuarem deslizando/girando ao teleportar
		peca.linear_velocity = Vector3.ZERO
		peca.angular_velocity = Vector3.ZERO
		
	# Reposicionar e limpar a bola
	var balls = get_tree().get_nodes_in_group("Balls")
	for ball in balls:
		ball.global_position = posicao_inicial_bola
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.lastTouch = null # Evita carregar informações de posse para o novo lance 
		
	# Forçar o turno para quem tomou o gol
	_forcar_turno_para_vitima(isHome)
	
	# Destrava as peças para recomeçar
	match_state.congelar_jogo(false)

func _forcar_turno_para_vitima(isHome: bool):
	if not match_state:
		return
	
	# isHome=true → bola entrou no gol do HOME → AWAY marcou → HOME é a vítima
	var vitima = match_state.turn.HOME if isHome else match_state.turn.AWAY
	match_state.forceTurn(vitima) 
