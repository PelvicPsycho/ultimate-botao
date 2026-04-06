extends Node3D

var todas_pecas: Array[Player] = []
var posicoes_iniciais_pecas: Dictionary = {}
var posicao_inicial_bola: Vector3

# CanvasLayer e Label criados por código para não precisar alterar a cena manualmente
var canvas_layer: CanvasLayer
var label_gol: Label

# Variável para referenciar o seu MatchState (assumindo que ele seja um Autoload ou esteja na cena)
@onready var match_state = $".."

func _ready() -> void:
	# Aguarda um frame para garantir que os outros nós terminaram o _ready
	await get_tree().process_frame
	
	if not match_state:
		match_state = get_tree().root.get_node("MatchScene") 
	#teste	
		
	# ---------------------------------------------------------
	# CORREÇÃO 1: Conexão de sinais padrão Godot 4 (Callable)
	# ---------------------------------------------------------
	var goals = get_tree().get_nodes_in_group("Goals")
	for goal in goals:
		# Usa a referência direta do sinal 'gol' em vez de string
		goal.gol.connect(gol_de_quem)
		
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
	var balls = get_tree().get_nodes_in_group("ball")
	if balls.size() > 0:
		posicao_inicial_bola = balls[0].global_position
		
	_configurar_ui()
	
func _configurar_ui():
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	label_gol = Label.new()
	label_gol.text = "GOL!"
	label_gol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_gol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_gol.add_theme_font_size_override("font_size", 64) # Fonte base grande
	
	# Centralizar perfeitamente no meio da tela
	label_gol.set_anchors_preset(Control.PRESET_CENTER)
	
	# Ocultar e zerar escala inicialmente
	label_gol.scale = Vector2.ZERO
	label_gol.visible = false
	
	canvas_layer.add_child(label_gol)
	
	# Ajustar o pivot para que o texto cresça a partir do centro dele mesmo
	await get_tree().process_frame # Espera renderizar para pegar o tamanho exato
	label_gol.pivot_offset = label_gol.size / 2

func gol_de_quem(isHome: bool):
	# Trava as interações para nenhum jogador clicar nas peças durante a comemoração
	for peca in todas_pecas:
		peca.disabled = true
	
	# Dispara a UI
	label_gol.visible = true
	label_gol.scale = Vector2.ZERO
	
	# Inicia o crescimento do Label por 1.5 segundos (usando Easing elástico para ficar dinâmico)
	var tween = create_tween()
	tween.tween_property(label_gol, "scale", Vector2(4, 4), 1.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Delay de 3 segundos exigido antes do jogo voltar
	await get_tree().create_timer(3.0).timeout
	
	# Reseta e esconde o Label
	label_gol.visible = false
	label_gol.scale = Vector2.ZERO
	
	# Reposicionar as peças para as Transforms originais
	for peca in todas_pecas:
		peca.global_transform = posicoes_iniciais_pecas[peca]
		# MUITO IMPORTANTE: Zerar velocidades para não continuarem deslizando/girando ao teleportar
		peca.linear_velocity = Vector3.ZERO
		peca.angular_velocity = Vector3.ZERO
		
	# Reposicionar e limpar a bola
	var balls = get_tree().get_nodes_in_group("ball")
	for ball in balls:
		ball.global_position = posicao_inicial_bola
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.lastTouch = null # Evita carregar informações de posse para o novo lance 
		
	# Forçar o turno para quem tomou o gol
	_forcar_turno_para_vitima(isHome)
	
	# Destrava as peças para recomeçar
	for peca in todas_pecas:
		peca.disabled = false

func _forcar_turno_para_vitima(isHome: bool):
	if not match_state:
		return
	
	# isHome=true → bola entrou no gol do HOME → AWAY marcou → HOME é a vítima
	var vitima = match_state.turn.HOME if isHome else match_state.turn.AWAY
	match_state.forceTurn(vitima) 
