extends Control

@export_group("Configurações de Nós e Cenas")
## Arraste o arquivo CardTorneio.tscn aqui
@export var cena_card_torneio: PackedScene 

## Arraste o nó Control vazio onde os cards vão ficar (sua antiga AreaCarrossel)
@export var area_carrossel: Control 

@export var seta_esquerda: TextureButton
@export var seta_direita: TextureButton

@export_group("Ajustes do Carrossel (Inspector)")
@export var espacamento_primeiros_vizinhos: float = 380.0
@export var espacamento_demais_cartas: float = 240.0
@export var escala_central_x: float = 1.0
@export var escala_central_y: float = 1.0
@export var escala_lateral_x: float = 0.75
@export var escala_lateral_y: float = 0.75
@export var opacidade_lateral: float = 0.4
@export var duracao_transicao: float = 0.35

@export_group("Física da Animação (Tweens)")
@export var tipo_transicao: Tween.TransitionType = Tween.TRANS_QUAD
@export var tipo_suavizacao: Tween.EaseType = Tween.EASE_OUT

var cartas: Array[Control] = []
var indice_atual = 0

func _ready():
	# 1. Limpa os cards de teste que estiverem DENTRO da area_carrossel
	for child in area_carrossel.get_children():
		if child is Control and child != seta_esquerda and child != seta_direita:
			child.free() 
	
	cartas.clear()
	
	var torneios = _carregar_cups_da_pasta()
	torneios.sort_custom(_ordenar_por_dificuldade)
	
	# 2. Instancia e adiciona os novos cards DENTRO da area_carrossel
	for cup in torneios:
		var novo_card = cena_card_torneio.instantiate()
		area_carrossel.add_child(novo_card)
		cartas.append(novo_card)
		novo_card.setup(cup)
	
	if seta_esquerda and not seta_esquerda.pressed.is_connected(_on_seta_esquerda_pressed):
		seta_esquerda.pressed.connect(_on_seta_esquerda_pressed)
	if seta_direita and not seta_direita.pressed.is_connected(_on_seta_direita_pressed):
		seta_direita.pressed.connect(_on_seta_direita_pressed)
		
	await get_tree().process_frame
	
	var index_encontrado = 0 # Por padrão, começa no torneio mais fácil (índice 0)
	
	if GameState.ultimo_torneio_jogado != "":
		# Procura em todos os torneios carregados qual tem o mesmo nome do salvo
		for i in range(torneios.size()):
			if torneios[i].cupName == GameState.ultimo_torneio_jogado:
				index_encontrado = i
				break
	
	if cartas.size() > 0:
		indice_atual = index_encontrado
		
	_atualizar_carrossel(false)
	
	# Reage ao redimensionamento da janela para reposicionar os cards
	area_carrossel.resized.connect(_on_area_carrossel_resized)


func _carregar_cups_da_pasta() -> Array[Cup]:
	var lista_de_cups: Array[Cup] = []
	var caminho_pasta = "res://Recursos/Cups/"
	var dir = DirAccess.open(caminho_pasta)
	
	if dir:
		var arquivos = dir.get_files()
		for arquivo in arquivos:
			var nome_limpo = arquivo.trim_suffix(".remap")
			if nome_limpo.ends_with(".tres"):
				var recurso = load(caminho_pasta + nome_limpo)
				if recurso is Cup:
					lista_de_cups.append(recurso)
	else:
		printerr("Pasta de Cups não encontrada: ", caminho_pasta)
	return lista_de_cups


func _ordenar_por_dificuldade(cup_a: Cup, cup_b: Cup) -> bool:
	return cup_a.cupRank > cup_b.cupRank


func _on_seta_esquerda_pressed():
	if indice_atual > 0:
		indice_atual -= 1
		_atualizar_carrossel(true)


func _on_seta_direita_pressed():
	if indice_atual < cartas.size() - 1:
		indice_atual += 1
		_atualizar_carrossel(true)


func _on_area_carrossel_resized():
	# Recalcula posições dos cards quando a janela é redimensionada
	if cartas.size() > 0:
		_atualizar_carrossel(false)


func _atualizar_carrossel(animado: bool):
	# 3. Calcula o centro usando apenas o tamanho da área do carrossel, não da tela inteira
	var centro_do_container = area_carrossel.size / 2.0
	
	for i in range(cartas.size()):
		var carta = cartas[i]
		var distancia_do_centro = i - indice_atual
		
		var offset_x = 0.0
		if distancia_do_centro != 0:
			var sinal = sign(distancia_do_centro)
			var distancia_absoluta = abs(distancia_do_centro)
			if distancia_absoluta == 1:
				offset_x = sinal * espacamento_primeiros_vizinhos
			else:
				offset_x = sinal * (espacamento_primeiros_vizinhos + (distancia_absoluta - 1) * espacamento_demais_cartas)
		
		var posicao_alvo_x = centro_do_container.x + offset_x
		var posicao_alvo = Vector2(posicao_alvo_x, centro_do_container.y)
		var e_a_carta_central = (distancia_do_centro == 0)
		
		var escala_alvo_x = escala_central_x if e_a_carta_central else escala_lateral_x
		var escala_alvo_y = escala_central_y if e_a_carta_central else escala_lateral_y
		var escala_alvo = Vector2(escala_alvo_x, escala_alvo_y)
		
		var opacidade_alvo = 1.0 if e_a_carta_central else opacidade_lateral
		
		carta.pivot_offset = carta.size / 2.0
		
		if e_a_carta_central:
			carta.z_index = 5
		else:
			carta.z_index = 5 - abs(distancia_do_centro)
		
		var posicao_ajustada = posicao_alvo - (carta.size / 2.0)
		
		if animado:
			var tween = create_tween().set_parallel(true)
			tween.set_trans(tipo_transicao).set_ease(tipo_suavizacao)
			tween.tween_property(carta, "position", posicao_ajustada, duracao_transicao)
			tween.tween_property(carta, "scale", escala_alvo, duracao_transicao)
			tween.tween_property(carta, "modulate", Color(opacidade_alvo, opacidade_alvo, opacidade_alvo, 1.0), duracao_transicao)
			if carta.has_method("definir_foco"):
				carta.definir_foco(e_a_carta_central)
		else:
			carta.position = posicao_ajustada
			carta.scale = escala_alvo
			carta.modulate = Color(opacidade_alvo, opacidade_alvo, opacidade_alvo, 1.0)
			if carta.has_method("definir_foco"):
				carta.definir_foco(e_a_carta_central)
