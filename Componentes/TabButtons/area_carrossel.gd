extends Control

@export_group("Configurações de Nós")
@export var cena_card_torneio: PackedScene 
@export var seta_esquerda: TextureButton
@export var seta_direita: TextureButton

@export_group("Ajustes do Carrossel (Inspector)")
## Distância em pixels entre a carta central e os primeiros vizinhos da esquerda e direita.
@export var espacamento_primeiros_vizinhos: float = 380.0

## Distância em pixels acumulada para as cartas seguintes (do segundo vizinho em diante).
@export var espacamento_demais_cartas: float = 240.0

## Escala horizontal (X) da carta que está no centro (em destaque).
@export var escala_central_x: float = 1.0

## Escala vertical (Y) da carta que está no centro (em destaque).
@export var escala_central_y: float = 1.0

## Escala horizontal (X) das cartas que estão nas laterais.
@export var escala_lateral_x: float = 0.75

## Escala vertical (Y) das cartas que estão nas laterais.
@export var escala_lateral_y: float = 0.75

## Opacidade (Transparência) das cartas laterais (0.0 a 1.0).
@export var opacidade_lateral: float = 0.4

## Tempo em segundos que a animação de deslize leva para completar.
@export var duracao_transicao: float = 0.35

@export_group("Física da Animação (Tweens)")
## Tipo de transição matemática para o movimento.
@export var tipo_transicao: Tween.TransitionType = Tween.TRANS_QUAD

## Modo de suavização da curva.
@export var tipo_suavizacao: Tween.EaseType = Tween.EASE_OUT

var cartas: Array[Control] = []
var indice_atual = 0

func _ready():
	# 1. Limpa qualquer carta "dummy/placeholder" que você deixou na cena para testar visualmente
	for child in get_children():
		if child is Control and child != seta_esquerda and child != seta_direita:
			child.free() # Remove imediatamente da árvore
	
	cartas.clear()
	
	# 2. Carrega e ordena os torneios
	var torneios = _carregar_cups_da_pasta()
	torneios.sort_custom(_ordenar_por_dificuldade)
	
	# 3. Spawna as cartas dinamicamente
	for cup in torneios:
		var novo_card = cena_card_torneio.instantiate()
		add_child(novo_card)
		cartas.append(novo_card)
		
		# Passa os dados do torneio para a carta preencher o texto
		novo_card.setup(cup)
	
	# 4. Conecta as setas (se já não estiverem conectadas)
	if seta_esquerda and not seta_esquerda.pressed.is_connected(_on_seta_esquerda_pressed):
		seta_esquerda.pressed.connect(_on_seta_esquerda_pressed)
	if seta_direita and not seta_direita.pressed.is_connected(_on_seta_direita_pressed):
		seta_direita.pressed.connect(_on_seta_direita_pressed)
		
	# Espera a UI inteira ser calculada
	await get_tree().process_frame
	
	if cartas.size() > 1:
		indice_atual = 1
		
	_atualizar_carrossel(false)


# --- NOVAS FUNÇÕES DE GERENCIAMENTO DE ARQUIVOS ---

func _carregar_cups_da_pasta() -> Array[Cup]:
	var lista_de_cups: Array[Cup] = []
	var caminho_pasta = "res://Recursos/Cups/"
	
	var dir = DirAccess.open(caminho_pasta)
	if dir:
		var arquivos = dir.get_files()
		for arquivo in arquivos:
			# O .remap é adicionado pelo Godot ao exportar o jogo. O trim garante que funcione no .exe
			var nome_limpo = arquivo.trim_suffix(".remap")
			
			if nome_limpo.ends_with(".tres"):
				var recurso = load(caminho_pasta + nome_limpo)
				if recurso is Cup:
					lista_de_cups.append(recurso)
	else:
		printerr("Pasta de Cups não encontrada: ", caminho_pasta)
		
	return lista_de_cups

func _ordenar_por_dificuldade(cup_a: Cup, cup_b: Cup) -> bool:
	# Como S=0 e F=6, queremos que o maior número venha primeiro para a carta mais fraca ficar na esquerda.
	return cup_a.cupRank > cup_b.cupRank

func _on_seta_esquerda_pressed():
	if indice_atual > 0:
		indice_atual -= 1
		_atualizar_carrossel(true)

func _on_seta_direita_pressed():
	if indice_atual < cartas.size() - 1:
		indice_atual += 1
		_atualizar_carrossel(true)

func _atualizar_carrossel(animado: bool):
	var centro_do_container = size / 2.0
	
	for i in range(cartas.size()):
		var carta = cartas[i]
		
		# Descobre a distância da carta atual para a selecionada
		var distancia_do_centro = i - indice_atual
		
		# 1. CÁLCULO DO ESPAÇAMENTO DINÂMICO
		var offset_x = 0.0
		
		if distancia_do_centro != 0:
			var sinal = sign(distancia_do_centro) # Retorna -1 se for esquerda, 1 se for direita
			var distancia_absoluta = abs(distancia_do_centro)
			
			# Se for o primeiro vizinho imediato (distância 1)
			if distancia_absoluta == 1:
				offset_x = sinal * espacamento_primeiros_vizinhos
			# Se estiver mais longe (distância 2, 3, etc)
			else:
				offset_x = sinal * (espacamento_primeiros_vizinhos + (distancia_absoluta - 1) * espacamento_demais_cartas)
		
		# Define a posição X final somando o offset calculado ao centro do pai
		var posicao_alvo_x = centro_do_container.x + offset_x
		var posicao_alvo = Vector2(posicao_alvo_x, centro_do_container.y)
		
		var e_a_carta_central = (distancia_do_centro == 0)
		
		# 2. Calcula Escala Alvo
		var escala_alvo_x = escala_central_x if e_a_carta_central else escala_lateral_x
		var escala_alvo_y = escala_central_y if e_a_carta_central else escala_lateral_y
		var escala_alvo = Vector2(escala_alvo_x, escala_alvo_y)
		
		var opacidade_alvo = 1.0 if e_a_carta_central else opacidade_lateral
		
		# Configura o pivô da carta para o centro absoluto dela para escalar corretamente
		carta.pivot_offset = carta.size / 2.0
		
		# Ajusta a ordem visual na árvore (Z-Index)
		if e_a_carta_central:
			carta.z_index = 5
		else:
			carta.z_index = 5 - abs(distancia_do_centro)
		
		# Ajusta para que a coordenada calculada seja o CENTRO real da carta
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
			# Aplicação instantânea sem transição
			carta.position = posicao_ajustada
			carta.scale = escala_alvo
			carta.modulate = Color(opacidade_alvo, opacidade_alvo, opacidade_alvo, 1.0)
			if carta.has_method("definir_foco"):
				carta.definir_foco(e_a_carta_central)
