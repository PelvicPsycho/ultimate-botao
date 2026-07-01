extends Control
class_name MenuRadialUI

signal carta_clicada(carta: Resource)

enum ModoDistribuicao { AGRUPADO_CENTRO, EXPANDIDO_ARCO }

@export_group("Configurações do Arco")
## O modo como as cartas vão se comportar quando houver menos de 5 unidades.
@export var modo: ModoDistribuicao = ModoDistribuicao.AGRUPADO_CENTRO
## Distância horizontal (X) e vertical (Y) do centro da peça até as cartas.
@export var raio_distancia := Vector2(150.0, 150.0)
## Ângulo de separação entre cada carta no modo Agrupado (em graus).
@export var espacamento_angular_graus: float = 35.0
## A abertura máxima do arco em graus (ex: 180 para um semicírculo perfeito).
@export var amplitude_maxima_arco: float = 180.0

@export_group("Cenas e Recursos")
@export var cena_botao_carta: PackedScene

@export_group("Pontos de Ação (PA)")
@export var textura_pa_cheio: Texture2D
	
@export_group("Configurações do PA (Arco Inferior)")
@export var raio_pa_linha_1: float = 80.0 
@export var raio_pa_linha_2: float = 110.0 
@export var espacamento_angular_pa: float = 30.0 
@export var tamanho_icone_linha_1: Vector2 = Vector2(45, 45) ## Tamanho da 1ª linha
@export var tamanho_icone_linha_2: Vector2 = Vector2(60, 60) ## Tamanho da 2ª linha

@export_group("Popup de Detalhes")
@export var popup_info: Control
@export var label_titulo: Label
@export var label_desc: Label
@export var icone_arte: TextureRect
@export var container_custo: HBoxContainer
@export var textura_custo_pa: Texture2D # O ícone da bolinha de PA que vai aparecer no custo

@export_group("Posicionamento Inteligente")
@export var painel_filho: Panel # Arraste o seu Panel filho aqui no Inspector
@export var posicao_padrao_cima: float = -420.0 # A posição original que você configurou
@export var posicao_alternativa_baixo: float = 130.0 # A posição dele quando for para baixo da peça
@export var posicao_padrao_x: float = 0.0 # Posição X padrão do painel
@export var posicao_x_direita: float = 300.0 # Posição X quando precisa ir para a direita
@export var posicao_x_esquerda: float = -300.0 # Posição X quando precisa ir para a esquerda
@export var limiar_borda_x: float = 300.0 # Distância mínima das bordas laterais
@export var limiar_borda_y: float = 0.0 # Distância mínima do topo da tela

var _tween_popup: Tween

var _container_pa_dinamico: Control
var _pa_atual: int = 0
var _max_pa: int = 6
var _icones_pa: Array[TextureRect] = []

var botoes_ativos: Array[TextureButton] = []
var is_open: bool = false
var _botao_hover_atual: TextureButton = null

var _parent_original: Node = null
var _canvas_layer: CanvasLayer = null

func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 1
	_canvas_layer.visible = false

## Filtra as cartas equipadas e desenha apenas as que são ATIVAS
func definir_cartas(todas_as_cartas: Array, pa_atual: int) -> void:
	_limpar_botoes_antigos()
	
	var cartas_ativas = todas_as_cartas.filter(func(carta): 
		return carta != null and not carta.is_passiva
	)
	
	var total_cartas = cartas_ativas.size()
	if total_cartas == 0:
		return
		
	for i in range(total_cartas):
		var dados_carta = cartas_ativas[i]
		var btn = cena_botao_carta.instantiate() as TextureButton
		
		btn.set_meta("dados_carta", dados_carta) # Salva os dados
		
		# Verifica se a carta custa mais PA do que a peça possui no momento
		if dados_carta.custo_energia > pa_atual:
			btn.disabled = true
			# Deixa a carta escura e um pouco transparente para indicar que não pode ser usada
			btn.modulate = Color(0.4, 0.4, 0.4, 0.8) 
		else:
			btn.disabled = false
			btn.modulate = Color.WHITE
		# -------------------------------------
		
		# 1. Garante a leitura do tamanho real da carta
		var tamanho_real = btn.size
		if tamanho_real == Vector2.ZERO:
			tamanho_real = btn.custom_minimum_size
		if tamanho_real == Vector2.ZERO:
			tamanho_real = Vector2(180.0, 130.0) 
			
		btn.size = tamanho_real
		btn.custom_minimum_size = tamanho_real
		
		# =========================================================
		# 2. A BONECA RUSSA: Cria o Wrapper (Âncora Orbital)
		var ancora_orbital = Control.new() 
		ancora_orbital.size = tamanho_real
		ancora_orbital.scale = Vector2.ZERO
		
		var angulo_rad = _calcular_angulo_para_indice(i, total_cartas)
		var posicao_alvo = Vector2(cos(angulo_rad), sin(angulo_rad)) * raio_distancia
		
		ancora_orbital.pivot_offset = tamanho_real / 2.0
		ancora_orbital.position = posicao_alvo - ancora_orbital.pivot_offset
		ancora_orbital.rotation = posicao_alvo.angle() + (PI / 2.0)
		# =========================================================
		
		# 3. Configura a carta (Botão) por dentro
		btn.position = Vector2.ZERO # 
		btn.rotation = 0.0
		
		# Configura a arte interna da carta
		var rect_arte = btn.get_node_or_null("ArteCarta") as TextureRect
		if rect_arte and dados_carta.arte:
			rect_arte.texture = dados_carta.arte
			
		# 4. Monta as camadas e joga na tela
		ancora_orbital.add_child(btn)
		add_child(ancora_orbital)
		botoes_ativos.append(btn)
		
		# Conexões
		btn.pressed.connect(func():
			print("🎯 MenuRadial: Botão clicado! Carta -> ", dados_carta.nome)
			carta_clicada.emit(dados_carta)
			fechar()
		)
		btn.set_meta("is_hovered", false)
		
	_animar_entrada_cartas()

## Realiza o cálculo dinâmico do ângulo centralizado para cada botão
func _calcular_angulo_para_indice(indice: int, total: int) -> float:
	# No círculo trigonométrico do Godot, -PI/2 (-90 graus) aponta diretamente para cima.
	var angulo_centro = -PI / 2.0 
	
	if total == 1:
		return angulo_centro
		
	var angulo_step: float = 0.0
	var largura_total_arco: float = 0.0
	
	match modo:
		ModoDistribuicao.AGRUPADO_CENTRO:
			# O espaçamento é constante, o arco encolhe se houver menos cartas
			angulo_step = deg_to_rad(espacamento_angular_graus)
			largura_total_arco = angulo_step * (total - 1)
			
		ModoDistribuicao.EXPANDIDO_ARCO:
			# O arco mantém o tamanho máximo, o vão entre as cartas aumenta se houver menos
			var arco_max_rad = deg_to_rad(amplitude_maxima_arco)
			angulo_step = arco_max_rad / (total - 1)
			largura_total_arco = arco_max_rad
			
	# Encontra o ponto de partida à esquerda para que a distribuição fique simétrica
	var angulo_inicial = angulo_centro - (largura_total_arco / 2.0)
	return angulo_inicial + (indice * angulo_step)

func _limpar_botoes_antigos() -> void:
	_botao_hover_atual = null
	for btn in botoes_ativos:
		if is_instance_valid(btn):
			var pai = btn.get_parent()
			if pai and pai != self:
				pai.queue_free() 
			else:
				btn.queue_free()
	botoes_ativos.clear()

func abrir() -> void:
	if is_open:
		return

	_parent_original = get_parent()

	if _canvas_layer.get_parent() == null:
		get_tree().root.add_child(_canvas_layer)

	var global_pos = global_position
	_parent_original.remove_child(self)
	_canvas_layer.add_child(self)
	global_position = global_pos

	_canvas_layer.visible = true
	is_open = true
	show()

func fechar() -> void:
	if not is_open:
		return
	is_open = false
	_limpar_botoes_antigos()
	hide()

	if _parent_original and is_instance_valid(_parent_original):
		var global_pos = global_position
		_canvas_layer.remove_child(self)
		_parent_original.add_child(self)
		global_position = global_pos

	_canvas_layer.visible = false

# ==========================================
# SISTEMA DE PONTOS DE AÇÃO (PA)
# ==========================================

func definir_pa(pa_atual: int, pa_maximo: int) -> void:
	_pa_atual = pa_atual
	_max_pa = clampi(pa_maximo, 1, 6) # Trava a segurança entre 1 e 6
	_criar_arcos_pa()
	_atualizar_pa()

func _criar_arcos_pa() -> void:
	if _container_pa_dinamico == null:
		_container_pa_dinamico = Control.new()
		_container_pa_dinamico.set_anchors_preset(Control.PRESET_CENTER)
		add_child(_container_pa_dinamico)
	else:
		for filho in _container_pa_dinamico.get_children():
			filho.queue_free()

	_icones_pa.clear()

	var qtd_primeira_fileira = min(_max_pa, 3)
	var qtd_segunda_fileira = max(0, _max_pa - 3)

	var angulo_centro_baixo = PI / 2.0 
	var passo_rad = deg_to_rad(espacamento_angular_pa)

	for i in range(_max_pa):
		var icone = TextureRect.new()
		icone.texture = textura_pa_cheio
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Variáveis base: A 1ª fileira (1 a 3 PAs) agora usa a linha MAIOR (Linha 2)
		var raio_atual = raio_pa_linha_2
		var indice_na_linha = i
		var total_na_linha = qtd_primeira_fileira
		var tamanho_atual = tamanho_icone_linha_2

		# Se for do 4º ao 6º PA, vai para a linha MENOR / ACIMA (Linha 1)
		if i >= 3:
			raio_atual = raio_pa_linha_1
			indice_na_linha = i - 3
			total_na_linha = qtd_segunda_fileira
			tamanho_atual = tamanho_icone_linha_1 

		# Aplica o tamanho escolhido na bolinha
		icone.custom_minimum_size = tamanho_atual
		icone.size = tamanho_atual
		icone.pivot_offset = tamanho_atual / 2.0 

		# Calcula a matemática do arco
		var largura_total = passo_rad * (total_na_linha - 1)
		var angulo_inicial = angulo_centro_baixo - (largura_total / 2.0)
		var angulo_final_icone = angulo_inicial + (indice_na_linha * passo_rad)

		# Posiciona e zera a escala para a sua animação atuar
		var posicao_alvo = Vector2(cos(angulo_final_icone), sin(angulo_final_icone)) * raio_atual
		icone.position = posicao_alvo - icone.pivot_offset
		icone.scale = Vector2.ZERO 
		icone.rotation = angulo_final_icone - (PI / 2.0)
		
		_container_pa_dinamico.add_child(icone)
		_icones_pa.append(icone)
		
	_animar_entrada_pa()

func _atualizar_pa() -> void:
	for i in range(_icones_pa.size()):
		if i < _pa_atual:
			_icones_pa[i].modulate = Color.WHITE
		else:
			# Bolinhas vazias ficam escuras e transparentes
			_icones_pa[i].modulate = Color(0.3, 0.3, 0.3, 0.5)

func _animar_entrada_pa() -> void:
	for i in range(_icones_pa.size()):
		var icone = _icones_pa[i]
		icone.scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_interval(i * 0.03) # Efeito cascata
		tween.tween_property(icone, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animar_saida_pa() -> void:
	for i in range(_icones_pa.size()):
		var icone = _icones_pa[i]
		var tween = create_tween()
		tween.tween_interval(i * 0.02)
		tween.tween_property(icone, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _animar_hover_botao(btn: TextureButton, entrando: bool) -> void:
	# A CURA DO PIVÔ: Forçamos o centro exato ignorando a engine de layout do Godot
#	btn.pivot_offset = btn.size / 2.0 
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
	if entrando:
		tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.2)
	else:
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)

# ==========================================
# HOVER SINTÉTICO OTIMIZADO (Baseado em Eventos)
# ==========================================
func _input(event: InputEvent) -> void:
	if not is_open:
		return
		
	if event is InputEventMouseMotion:
		var novo_botao_hover: TextureButton = null
		
		# Procura qual carta está sob o mouse neste frame (de trás para frente)
		for i in range(botoes_ativos.size() - 1, -1, -1):
			var btn = botoes_ativos[i]
			if not is_instance_valid(btn) or btn.disabled: 
				continue
				
			var rect = Rect2(Vector2.ZERO, btn.size)
			if rect.has_point(btn.get_local_mouse_position()):
				novo_botao_hover = btn
				break # Encontrou o foco atual, ignora as outras cartas sobrepostas
				
		# Se o foco mudou (mudou de carta OU o mouse foi para o vazio)
		if novo_botao_hover != _botao_hover_atual:
			
			# 1. Desativa a carta anterior imediatamente
			if is_instance_valid(_botao_hover_atual):
				_botao_hover_atual.set_meta("is_hovered", false)
				_animar_hover_botao(_botao_hover_atual, false)
			
			# 2. Atualiza a referência para a nova carta
			_botao_hover_atual = novo_botao_hover
			
			# 3. Ativa a nova carta se ela existir
			if is_instance_valid(_botao_hover_atual):
				_botao_hover_atual.set_meta("is_hovered", true)
				_animar_hover_botao(_botao_hover_atual, true)
				_mostrar_detalhes_carta(_botao_hover_atual.get_meta("dados_carta"))
			else:
				# Se o mouse foi para o vazio total, esconde o painel de detalhes
				if popup_info and popup_info.visible:
					_esconder_detalhes_carta()

func _animar_entrada_cartas() -> void:
	for i in range(botoes_ativos.size()):
		var btn = botoes_ativos[i]
		if not is_instance_valid(btn):
			continue
			
		# Pegamos a âncora para animar, preservando a escala original do botão para o Hover
		var ancora = btn.get_parent()
		
		var tween = create_tween()
		tween.tween_interval(i * 0.04) # Efeito de cascata (40ms entre cada carta)
		tween.tween_property(ancora, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
	
	_adaptar_painel_a_tela() # Arruma a localização do painel de informações

func _mostrar_detalhes_carta(carta: CardResource) -> void:
	if not popup_info: return
	
	# Preenche os textos
	if label_titulo: label_titulo.text = carta.nome
	if label_desc: label_desc.text = carta.descricao
	if icone_arte: icone_arte.texture = carta.arte
	
	# Monta os ícones de custo de PA
	if container_custo:
		for child in container_custo.get_children():
			child.queue_free()
			
		for i in range(carta.custo_energia):
			var rect = TextureRect.new()
			rect.texture = textura_custo_pa
			rect.custom_minimum_size = Vector2(24, 24)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container_custo.add_child(rect)

	# Exibe e anima
	popup_info.show()
	
	if _tween_popup and _tween_popup.is_running():
		_tween_popup.kill()
		
	_tween_popup = create_tween()
	# Se a opacidade já estiver 1.0 (passou de uma carta para outra), a transição não pisca
	_tween_popup.tween_property(popup_info, "modulate:a", 1.0, 0.15)


func _esconder_detalhes_carta() -> void:
	if not popup_info or not popup_info.visible: return
	
	if _tween_popup and _tween_popup.is_running():
		_tween_popup.kill()
		
	_tween_popup = create_tween()
	_tween_popup.tween_property(popup_info, "modulate:a", 0.0, 0.1)
	# Garante que o painel saia da tela ao terminar de ficar invisível
	_tween_popup.tween_callback(popup_info.hide)

func _adaptar_painel_a_tela() -> void:
	if not painel_filho:
		return
	
	var viewport_width = get_viewport().get_visible_rect().size.x
	# O pivot é top-left → subtrai meia largura para que os valores exportados
	# representem o centro do painel, não a borda esquerda
	var meia_largura = painel_filho.size.x / 2.0
	
	# Reseta para as posições padrão (cima + X centralizado)
	painel_filho.position.y = posicao_padrao_cima
	painel_filho.position.x = posicao_padrao_x - meia_largura
	painel_filho.force_update_transform()
	
	# Detecta proximidade das bordas
	var perto_do_topo: bool = painel_filho.global_position.y < limiar_borda_y
	var perto_da_direita: bool = painel_filho.global_position.x + painel_filho.size.x > viewport_width - limiar_borda_x
	var perto_da_esquerda: bool = painel_filho.global_position.x < limiar_borda_x
	
	# ── Vertical: perto do topo → joga para baixo ──
	if perto_do_topo:
		painel_filho.position.y = posicao_alternativa_baixo
	
	# ── Horizontal: perto da direita → joga para esquerda / perto da esquerda → joga para direita ──
	if perto_da_direita:
		painel_filho.position.x = posicao_x_esquerda - meia_largura
		painel_filho.position.y = -painel_filho.size.y / 2.0
	elif perto_da_esquerda:
		painel_filho.position.x = posicao_x_direita - meia_largura
		painel_filho.position.y = -painel_filho.size.y / 2.0


#func _on_button_pressed() -> void:
	## 1. QUEM É ELA: Criamos a lista vazia aqui, tipada para aceitar apenas CardResource
	#var cartas_teste: Array[CardResource] = []
	#
	## Coloque aqui os IDs ÚNICOS das cartas (o campo id_unico do CardResource)
	#var ids_cartas = ["atracao_01", "bola_leve_01", "encolher_01", "aumentar_01", "empurrao_aliado_01"]
	#
	#for id in ids_cartas:
		## Puxa a carta diretamente da memória RAM através do seu Singleton!
		#var carta_real = Database.get_carta(id)
		#
		#if carta_real:
			## Se achou no banco, coloca dentro da nossa lista!
			#cartas_teste.append(carta_real)
		#else:
			#push_warning("⚠️ DEBUG: Carta não encontrada no Database -> ID: ", id)
			#
	#print("🛠️ DEBUG: Iniciando simulação com ", cartas_teste.size(), " cartas do Database...")
	#
	## Define os Pontos de Ação da peça: 4 atuais, 6 máximos
	#var pa_atual = 3
	#var pa_maximo = 6
	#definir_pa(pa_atual, pa_maximo)
	#
	## Constrói o menu radial com a lista de cartas carregadas
	#definir_cartas(cartas_teste, pa_atual)
	#
	## Chama a abertura para disparar as animações
	#abrir()
