extends Control
class_name ElencoMenuManager

enum CategoryTab { PIECES, CARDS }

#var controle_sob_o_mouse: Control = null #DEBUG

# --- VARIÁVEIS DE ESTADO ---
var current_slot: int = 1
var current_tab: CategoryTab = CategoryTab.PIECES
var item_em_inspecao: Resource = null 
var inspecionando_carta_equipada: bool = false
var grupo_janela_esquerda := ButtonGroup.new()
var grupo_janela_direita := ButtonGroup.new()
var numero_peca_topbar_escolhida: String

var az_ascending := true
var rank_ascending := true
var data_ascending := true # Começa como true (Ascendente)
var sort_mode := 3


# Largura do pai do grid (inventory_list) medida quando o grid está VAZIO,
# usada para calcular o tamanho ideal dos itens ANTES de populá-lo.
var _saved_pai_width_pieces: float = 0.0
var _saved_pai_width_cards: float = 0.0

# --- REFERÊNCIAS DE NÓS (INSPETOR) ---
@export_group("Panel Containers + Stretch Ratios")
@export var LeftWindowPanelStrech_Peca: float = 0.76
@export var LeftWindowPanelStrech_Card: float = 1.05
@export var CenterWindowPanelStrech_Peca: float = 1
@export var CenterWindowPanelStrech_Card: float = 0.8
@export var RightWindowPanelStrech_Peca: float = 1.1
@export var RightWindowPanelStrech_Card: float = 1.26
@export var LeftWindow_PanelContainer: PanelContainer
@export var CenterWindow_PanelContainer: PanelContainer
@export var RightWindow_PanelContainer: PanelContainer


@export_group("Navegação Superior")
@export var slot_buttons: Array[TextureButton]

@export_group("Texturas dos Slots (Topo)")
@export var textura_slot_selecionado: Texture2D ##DELETAR
@export var textura_slot_inativo: Texture2D ##DELETAR

@export_group("Menu Lateral")
@export var tab_pieces_btn: TextureButton
@export var tab_cards_btn: TextureButton
@export var textura_aba_ativa: Texture2D 
@export var textura_aba_inativa: Texture2D

@export_group("Menu Lateral - Ações")
@export var btn_salvar_sair: Button

@export_group("Filtros")
@export var az_filter_btn: TextureButton
@export var rank_filter_btn: TextureButton
@export var date_filter_btn: TextureButton

@export_group("Janela Esquerda")
@export var inventory_list: GridContainer 
@export var inventory_margincontainer: MarginContainer

@export_group("Janela Central")
@export var central_descricao_label: Label
@export var central_nome_label: Label
#@export var central_arte_rect: TextureRect
@export var center_action_btn: TextureButton
@export var center_action_label: Label
@export var display_carta_aspectratioc: AspectRatioContainer


@export_group("Janela Central - Visual")
@export var center_card_view: MarginContainer
@export var center_peca_view: MarginContainer

@export_group("Janela Central - Visibilidade")
@export var center_pai_margincontainer: MarginContainer 
@export var center_plainmsg_vbox: VBoxContainer

@export_group("Janela Central - Elementos da Peça")
@export var central_forca_label: Label
@export var central_AP_label: Label
@export var central_RP_label: Label
@export var central_rank_label: Label
@export var center_peca_grid: GridContainer
@export var cw_button_texture: TextureRect
@export var cw_button_label: Label
@export var center_peca_slots_hbox: HBoxContainer
@export var cw_contagem_slots_label: Label
@export var cw_pecaname_margincontainer: MarginContainer
@export var CW_Control_Stats: Control

@export_group("Janela Central - Carta")
#@export var slots_que_ocupa_hbox: HBoxContainer
@export var icone_de_slot_textura: Texture2D
@export var thumbnail_video_wrapper: Control #Janela central
@export var central_video_player: VideoStreamPlayer


@export_group("Janela Direita")
@export var right_nome_label: Label
@export var rw_forca_label: Label
@export var rw_AP_label: Label
@export var rw_RP_label: Label
@export var rw_rank_label: Label
@export var right_window_grid: GridContainer
@export var rw_contagem_slots_label: Label
@export var rw_button_texture: TextureRect 
@export var rw_button_label: Label 

@export_group("Janela Direita - Slots Visual")
@export var right_slots_indicator_hbox: HBoxContainer
@export var icone_slot_ocupado: Texture2D
@export var icone_slot_livre: Texture2D  

@export_group("Cenas")
@export var cena_item_carta: PackedScene
@export var cena_item_peca: PackedScene
@export var cena_carta_pequena: PackedScene
@export var cena_moldura_slot: PackedScene
@export var tamanho_das_cartas:= Vector2(110,110)

@export_group("Tamanho dos Itens no Inventário")
## Deixe Vector2.ZERO para cálculo automático. Ex: Vector2(140, 140) para peças.
@export var tamanho_manual_peca: Vector2 = Vector2.ZERO
## Deixe Vector2.ZERO para cálculo automático. Ex: Vector2(280, 90) para cartas.
@export var tamanho_manual_carta: Vector2 = Vector2.ZERO

@export_group("Sistema de Vídeo Cinema")
@export var overlay_video: Control
@export var fundo_escuro: ColorRect
@export var video_container: Control
@export var popup_video_player: VideoStreamPlayer
@export var btn_abrir_video: TextureButton
@export var btn_fechar_video: Button

@export_group("Visuais Dinâmicos da Peça (PecaMenuUI)")
@export var center_peca_visual: PecaMenuUI
@export var right_peca_visual: PecaMenuUI
@export var numero_peca_label: Label
## Coloque aqui os 5 nós PecaMenuUI que ficam dentro dos botões do topo, na ordem correta (1 a 5).
@export var top_slots_visuais: Array[PecaMenuUI]

# --- INICIALIZAÇÃO ---
func _ready() -> void:
	visibility_changed.connect(_ao_mudar_visibilidade)
	_connect_signals()
	_atualizar_nomes_dos_slots()
	_select_slot(1)
	_clear_center_window()
	_atualizar_visuais_dos_filtros()
	btn_abrir_video.pressed.connect(_abrir_modo_cinema)
	btn_fechar_video.pressed.connect(_fechar_modo_cinema)
	
	# Impede que o GridContainer estique verticalmente dentro do pai.
	# Assim ele "abraça" o conteúdo e as linhas não inflam com poucos itens.
	inventory_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Se já estiver visível, dispara a medição/população agora
	if visible:
		call_deferred("_ao_mudar_visibilidade")

#func _process(_delta: float) -> void:
	## Pega exatamente o Control que está debaixo do ponteiro do mouse agora
	#var controle_atual = get_viewport().gui_get_hovered_control()
	#
	## Se for diferente do que estava no frame anterior, a gente imprime!
	#if controle_atual != controle_sob_o_mouse:
		#controle_sob_o_mouse = controle_atual
		#
		#if controle_atual != null:
			#print("🔎 [DEBUG MOUSE] Apontando para: ", controle_atual.name, " | Tipo: ", controle_atual.get_class())
		#else:
			#print("🔎 [DEBUG MOUSE] Apontando para: NADA (Fundo/Canvas)")

func _connect_signals() -> void:
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.pressed.connect(func(): _select_slot(i + 1))
		
	tab_pieces_btn.pressed.connect(func(): _switch_tab(CategoryTab.PIECES))
	tab_cards_btn.pressed.connect(func(): _switch_tab(CategoryTab.CARDS))
	center_action_btn.pressed.connect(_on_center_action_pressed)
	
	if az_filter_btn:
		az_filter_btn.pressed.connect(_on_az_filter_pressed)
	if rank_filter_btn:
		rank_filter_btn.pressed.connect(_on_rank_filter_pressed)
	if date_filter_btn:
		date_filter_btn.pressed.connect(_on_date_filter_pressed)
	
	if btn_salvar_sair:
		btn_salvar_sair.pressed.connect(_on_btn_salvar_sair_pressed)


# --- NAVEGAÇÃO E ABAS ---
func _select_slot(slot_index: int) -> void:
	current_slot = slot_index
	
	var botao_clicado = slot_buttons[current_slot - 1] #Repassa o numero da camisa
	var label_numero = botao_clicado.get_node_or_null("Numero") as Label
	if label_numero:
		numero_peca_topbar_escolhida = label_numero.text
		if numero_peca_label:
			numero_peca_label.text = numero_peca_topbar_escolhida
	
	# === INÍCIO DO DEBUG DE CARTAS DO ELENCO ===
	if current_slot - 1 >= 0 and current_slot - 1 < GameState.jogadores.size():
		var peca_selecionada = GameState.jogadores[current_slot - 1]
		if peca_selecionada != null:
			var nome_peca = peca_selecionada.nome if "nome" in peca_selecionada else "Peça Desconhecida"
			#print("\n=== DEBUG MENU ELENCO: Slot ", current_slot, " (", nome_peca, ") ===")
			#print("Tamanho real do array 'slotsUpgrates' nesta peça: ", peca_selecionada.slotsUpgrates.size())
			
			for i in range(peca_selecionada.slotsUpgrates.size()):
				var c = peca_selecionada.slotsUpgrates[i]
				if c == null:
					pass
					#print("  Slot [", i, "]: VAZIO (null)")
				else:
					var nome_carta = c.nome if "nome" in c else "Sem Nome"
					#print("  Slot [", i, "]: ", nome_carta, " | Custo: ", c.custoSlotes)
			#print("===================================================\n")
	# === FIM DO DEBUG ===

	_atualizar_visual_dos_slots()
	
	_update_right_window()
	
#	GameState.imprimir_status_do_time()
	
	if item_em_inspecao is CardResource and inspecionando_carta_equipada:
		_clear_center_window()
	elif item_em_inspecao is CardResource and not inspecionando_carta_equipada:
		_inspecionar_item_na_janela_central(item_em_inspecao, false)

## Dado a largura do pai e número de colunas, calcula quantos px cada item deve ter.
## Se largura_pai for <= 0, retorna 100 como fallback seguro.
func _tamanho_da_largura(largura_pai: float, cols: int) -> int:
	if largura_pai <= 0.0:
		return 100 # fallback seguro
	var sep_h: int = inventory_list.get_theme_constant("h_separation")
	var espaco: float = (largura_pai - 16.0) - float(sep_h) * float(cols - 1)
	return max(int(floor(espaco / float(cols))), 24)

func _switch_tab(tab: CategoryTab) -> void:
	if current_tab != tab:
		center_pai_margincontainer.visible = false
		center_plainmsg_vbox.visible = true
	#else:
		#cw_pecaname_margincontainer.visible = false
		#CW_Control_Stats.visible = false
	current_tab = tab
	
	if current_tab == CategoryTab.PIECES:
#		center_plainmsg_vbox.custom_minimum_size.x = 528
		inventory_list.add_theme_constant_override("v_separation", 15)
		inventory_margincontainer.add_theme_constant_override("margin_right", 40)
		inventory_margincontainer.add_theme_constant_override("margin_bottom", 15)
		LeftWindow_PanelContainer.size_flags_stretch_ratio = LeftWindowPanelStrech_Peca
		CenterWindow_PanelContainer.size_flags_stretch_ratio = CenterWindowPanelStrech_Peca
		RightWindow_PanelContainer.size_flags_stretch_ratio = RightWindowPanelStrech_Peca
		tab_pieces_btn.texture_normal = textura_aba_ativa
		tab_cards_btn.texture_normal = textura_aba_inativa
		
		var num_slots = slot_buttons.size()
		var pecas_livres: Array = []
		
		if GameState.jogadores.size() > num_slots:
			pecas_livres = GameState.jogadores.slice(num_slots)
		
		for peca_id in GameState.pecas_desbloqueadas:
			if GameState.pecas_desbloqueadas[peca_id] > 0:
				var peca_ref = Database.pecas_db.get(peca_id)
				if peca_ref:
					pecas_livres.append(peca_ref)
		
		_apply_sort(pecas_livres)
		inventory_list.columns = 2
		
		var tamanho: int
		if tamanho_manual_peca != Vector2.ZERO:
			tamanho = int(tamanho_manual_peca.x)
		else:
			tamanho = _tamanho_da_largura(_saved_pai_width_pieces, 2)
		_popular_lista(pecas_livres, tamanho)
		
	elif current_tab == CategoryTab.CARDS:
		inventory_list.add_theme_constant_override("v_separation", 10)
		center_plainmsg_vbox.custom_minimum_size.x = 60
		inventory_margincontainer.add_theme_constant_override("margin_right", 40)
		inventory_margincontainer.add_theme_constant_override("margin_bottom", 25)
		LeftWindow_PanelContainer.size_flags_stretch_ratio = LeftWindowPanelStrech_Card
		CenterWindow_PanelContainer.size_flags_stretch_ratio = CenterWindowPanelStrech_Card
		RightWindow_PanelContainer.size_flags_stretch_ratio = RightWindowPanelStrech_Card
		tab_pieces_btn.texture_normal = textura_aba_inativa
		tab_cards_btn.texture_normal = textura_aba_ativa
		
		inventory_list.columns = 1
		
		var todas_as_cartas = []
		for id_carta in GameState.cartas_desbloqueadas.keys():
			var carta_real = Database.get_carta(id_carta)
			if carta_real != null:
				todas_as_cartas.append(carta_real)
		
		var status_de_uso_das_cartas: Dictionary = {} 
		for peca in GameState.jogadores:
			for carta in peca.slotsUpgrates:
				if carta != null:
					if status_de_uso_das_cartas.has(carta.id_unico):
						status_de_uso_das_cartas[carta.id_unico].append(peca.nome)
					else:
						status_de_uso_das_cartas[carta.id_unico] = [peca.nome]
		
		_apply_sort(todas_as_cartas)
		
		var tamanho: int
		if tamanho_manual_carta != Vector2.ZERO:
			tamanho = int(tamanho_manual_carta.x)
		else:
			tamanho = _tamanho_da_largura(_saved_pai_width_cards, 1)
		_popular_lista_de_cartas(todas_as_cartas, status_de_uso_das_cartas, tamanho)


# --- FILTROS DE ORDENAÇÃO ---
func _on_az_filter_pressed() -> void:
	if sort_mode != 1:
		# Se não era o ativo, ativa o A-Z no modo padrão (Crescente/Verde)
		sort_mode = 1
		az_ascending = true
	else:
		# Se já era o ativo, apenas inverte a ordem
		az_ascending = not az_ascending
		
	_atualizar_visuais_dos_filtros()
	_switch_tab(current_tab)

func _on_rank_filter_pressed() -> void:
	if sort_mode != 2:
		# Se não era o ativo, ativa o Rank no modo padrão (Melhor pro Pior/Verde)
		sort_mode = 2
		rank_ascending = true
	else:
		# Se já era o ativo, apenas inverte a ordem
		rank_ascending = not rank_ascending
		
	_atualizar_visuais_dos_filtros()
	_switch_tab(current_tab)

func _on_date_filter_pressed() -> void:
	if sort_mode != 3:
		# Se não era o ativo, ativa a Data no modo padrão (Mais antigos primeiro/Verde)
		sort_mode = 3
		data_ascending = true 
	else:
		# Se já era o ativo, apenas inverte a ordem (Mais novos primeiro/Laranja)
		data_ascending = not data_ascending
		
	_atualizar_visuais_dos_filtros()
	_switch_tab(current_tab)

func _atualizar_visuais_dos_filtros() -> void:
	# 1. Reseta TODOS os botões para branco
	if az_filter_btn: az_filter_btn.modulate = Color.WHITE
	if rank_filter_btn: rank_filter_btn.modulate = Color.WHITE
	if date_filter_btn: date_filter_btn.modulate = Color.WHITE
	
	# 2. Define as cores
	var cor_crescente = Color(0.5, 1.0, 0.5)  # Verde
	var cor_decrescente = Color(1.0, 0.6, 0.2)  # Laranja
	
	# 3. Pinta apenas o ativo usando match
	match sort_mode:
		1:
			if az_filter_btn: az_filter_btn.modulate = cor_crescente if az_ascending else cor_decrescente
		2:
			if rank_filter_btn: rank_filter_btn.modulate = cor_crescente if rank_ascending else cor_decrescente
		3:
			if date_filter_btn: date_filter_btn.modulate = cor_crescente if data_ascending else cor_decrescente

func _apply_sort(array: Array) -> void:
	match sort_mode:
		1: _sort_by_name(array)
		2: _sort_by_rank(array)
		3: _sort_by_date(array)

func _sort_by_date(array: Array) -> void:
	# Se for data_ascending (Verde), não fazemos nada, pois o Godot já entrega 
	# o array na ordem de obtenção (os primeiros do array são os mais antigos).
	# Só precisamos reverter se o jogador quiser os mais novos primeiro (Laranja).
	if not data_ascending:
		array.reverse()

func _sort_by_name(array: Array) -> void:
	array.sort_custom(func(a, b):
		# Puxa a propriedade direto (Duck Typing)
		var nome_a = a.nome.to_lower()
		var nome_b = b.nome.to_lower()
		
		# Retorna a comparação de acordo com a ordem
		return nome_a < nome_b if az_ascending else nome_a > nome_b
	)

func _sort_by_rank(array: Array) -> void:
	array.sort_custom(func(a, b):
		var ra := _rank_value(a)
		var rb := _rank_value(b)
		return ra < rb if rank_ascending else ra > rb
	)

## Menor = melhor: S=0 → F=5 (peças), RARA=0 → NORMAL=2 (cartas).
func _rank_value(item: Resource) -> int:
	if item is TeamPlayer:
		return item.rank  # enum: S=0, A=1, B=2, C=3, D=4, F=5
	elif item is CardResource:
		return 2 - item.raridade  # RARA=0, INCOMUM=1, NORMAL=2
	return 99


# --- POPULANDO LISTAS (JANELA ESQUERDA) ---
func _popular_lista_de_cartas(lista_de_cartas: Array, status_de_uso: Dictionary, tamanho_item: int) -> void:
	for child in inventory_list.get_children():
		inventory_list.remove_child(child) # Tira do layout INSTANTANEAMENTE
		child.queue_free() # Deleta da memória no fim do frame
	
	var size_item = Vector2(tamanho_item, 90)
		
	for carta in lista_de_cartas:
		if cena_item_carta:
			var btn_item = cena_item_carta.instantiate()
			btn_item.button_group = grupo_janela_esquerda
			btn_item.size_flags_horizontal = Control.SIZE_FILL
			btn_item.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			btn_item.custom_minimum_size = size_item
			inventory_list.add_child(btn_item)
			
			var usuarios = status_de_uso.get(carta.id_unico, [])
			var esta_em_uso = usuarios.size() > 0
			var nome_do_usuario = usuarios[0] if esta_em_uso else ""
			
			if btn_item.has_method("setup_item"):
				btn_item.setup_item(carta, GameState.quantas_cartas(carta.id_unico))
			
			btn_item.pressed.connect(func(): _inspecionar_item_na_janela_central(carta, false, esta_em_uso, nome_do_usuario))

func _popular_lista(lista_de_itens: Array, tamanho_item: int) -> void:
	for child in inventory_list.get_children():
		inventory_list.remove_child(child) # Tira do layout INSTANTANEAMENTE
		child.queue_free() # Deleta da memória no fim do frame
	
	var cols = inventory_list.columns
	var size_item = Vector2(tamanho_item, tamanho_item) if cols > 1 else Vector2(tamanho_item, 90)
		
	for item in lista_de_itens:
		var btn_item = null
		
		if item is CardResource and cena_item_carta:
			btn_item = cena_item_carta.instantiate()
		elif item is TeamPlayer and cena_item_peca:
			btn_item = cena_item_peca.instantiate()
			
		if btn_item:
			btn_item.button_group = grupo_janela_esquerda
			if item is TeamPlayer:
				btn_item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND# | Control.SIZE_FILL
			else:
				btn_item.size_flags_horizontal = Control.SIZE_FILL
			btn_item.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			btn_item.custom_minimum_size = size_item
			print (size_item)
			inventory_list.add_child(btn_item)
			if btn_item.has_method("setup_item"):
				var qtd := 0
				if item is TeamPlayer:
					if not GameState.jogadores.has(item):
						qtd = GameState.quantas_pecas(item.id_unico)
				elif item is CardResource:
					qtd = GameState.quantas_cartas(item.id_unico)
				btn_item.setup_item(item, qtd)
			
			btn_item.pressed.connect(func(): _inspecionar_item_na_janela_central(item))
			

# --- INSPEÇÃO E VISUALIZAÇÃO ---
func _inspecionar_item_na_janela_central(item: Resource, is_equipped_here: bool = false, _esta_em_outro_jogador: bool = false, _nome_do_outro_jogador: String = ""):
	if center_pai_margincontainer: center_pai_margincontainer.visible = true
	if center_plainmsg_vbox: center_plainmsg_vbox.visible = false
	item_em_inspecao = item
	inspecionando_carta_equipada = is_equipped_here
	
	center_action_btn.disabled = false
	center_action_label.modulate = Color.WHITE 
	central_nome_label.texto_auto_ajustavel = item.nome
	
	if item is CardResource:
		center_card_view.visible = true
		center_peca_view.visible = false
		LeftWindow_PanelContainer.size_flags_stretch_ratio = LeftWindowPanelStrech_Card
		CenterWindow_PanelContainer.size_flags_stretch_ratio = CenterWindowPanelStrech_Card
		RightWindow_PanelContainer.size_flags_stretch_ratio = RightWindowPanelStrech_Card
		cw_pecaname_margincontainer.visible = false
		CW_Control_Stats.visible = false
		
		#if cw_button_texture:
			#cw_button_texture.visible = false 
		
		central_descricao_label.text = _gerar_texto_detalhado_carta(item)
		
		display_carta_aspectratioc.setup(item)
		
		# --- LÓGICA DO THUMBNAIL DE VÍDEO ---
		#if "video_preview" in item and item.video_preview != null:
			#thumbnail_video_wrapper.visible = true
			#
			## Tira o pause da inspeção anterior ANTES de trocar o vídeo!
			#central_video_player.paused = false 
			#
			## Carrega o vídeo e dá o Play invisível
			#central_video_player.stream = item.video_preview
			#central_video_player.play()
			#
			### Esperamos a placa de vídeo desenhar o frame na tela
			##await get_tree().process_frame
			##await get_tree().process_frame
			##
			### Agora que o frame está na tela, congelamos o vídeo!
			##central_video_player.paused = true
			#
		#else:
			## Não tem vídeo
			#thumbnail_video_wrapper.visible = false
			#central_video_player.paused = false # Despausa por segurança
			#central_video_player.stop()
		
#		if item.arte:
#			central_arte_rect.texture = item.arte
		
		#for child in slots_que_ocupa_hbox.get_children():
			#child.queue_free()
		#for i in range(item.custoSlotes):
			#var icone_slot = TextureRect.new()
			#icone_slot.texture = icone_de_slot_textura 
			#icone_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			#icone_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			#icone_slot.custom_minimum_size = Vector2(40, 40)
			#slots_que_ocupa_hbox.add_child(icone_slot)
			
		if inspecionando_carta_equipada:
			center_action_btn.disabled = false
			center_action_label.text = "Desequipar"
			center_action_label.modulate = Color.WHITE
		else:
			if not GameState.tem_carta(item.id_unico):
				center_action_btn.disabled = true
				center_action_label.text = "Indisponível"
				center_action_label.modulate = Color.RED
				
			else:
				var peca_atual = GameState.jogadores[current_slot - 1]
				var slots_usados = 0
				for carta in peca_atual.slotsUpgrates:
					if carta != null:
						slots_usados += carta.custoSlotes
						
				var slots_livres = peca_atual.quantosSlotes - slots_usados
				
				# --- VALIDAÇÃO DE PA COM O SEU CARD RESOURCE ---
				var status_peca = _get_status_calculado(peca_atual)
				var pa_disponivel = status_peca.pa
				
				# Lê o custo real de energia da carta que está no seu script
				var custo_ativacao_carta = item.custo_energia if "custo_energia" in item else 0
				
				# 1. Verifica se tem slot livre na mochila
				if item.custoSlotes > slots_livres:
					center_action_btn.disabled = true
					center_action_label.text = "Sem Slots"
					center_action_label.modulate = Color.RED
					
				# 2. Verifica se a peça tem PA base suficiente para usar a carta ativa
				elif custo_ativacao_carta > pa_disponivel:
					center_action_btn.disabled = true
					center_action_label.text = "PA Insuficiente"
					center_action_label.modulate = Color(1.0, 0.5, 0.0) # Laranja
					
				# 3. Tudo certo, libera o botão para equipar
				else:
					center_action_btn.disabled = false
					center_action_label.text = "Equipar"
					center_action_label.modulate = Color.WHITE
				
	elif item is TeamPlayer:
		center_card_view.visible = false
		center_peca_view.visible = true
		cw_pecaname_margincontainer.visible = true
		LeftWindow_PanelContainer.size_flags_stretch_ratio = LeftWindowPanelStrech_Peca
		CenterWindow_PanelContainer.size_flags_stretch_ratio = CenterWindowPanelStrech_Peca
		RightWindow_PanelContainer.size_flags_stretch_ratio = RightWindowPanelStrech_Peca
		CW_Control_Stats.visible = true
		
		if is_instance_valid(center_peca_visual):
			center_peca_visual.setup_peca(item)
		
		var status = _get_status_calculado(item)
		var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, item.quantosSlotes]
		print (texto_status)
		central_AP_label.text = "Pontos de Ação   ·   %d AP" % [status.pa]
		central_forca_label.text = "Força   ·   lvl %d" % item.level_force#[status.forca]
		central_RP_label.text = "RP: %d" % (status.pa + item.level_force + item.quantosSlotes)
		central_rank_label.text = str(TeamPlayer.Rank.keys()[item.estimateRank()])[-1]
		#center_peca_stats.text = texto_status
		
		# --- ATUALIZAÇÃO DO GRID CENTRAL COM MOLDURAS FIXAS ---
		for child in center_peca_grid.get_children():
			child.queue_free()
			
		# 1. Filtra apenas as cartas reais equipadas (ignora os nulls da array)
		var cartas_reais_centro = []
		for carta in item.slotsUpgrates:
			if carta != null:
				cartas_reais_centro.append(carta)
				
# 2. Define a regra fixa de 8 ou 10 molduras na tela baseada nas cartas EQUIPADAS
		var total_slots_centro = 8
		if cartas_reais_centro.size() > 8:
			total_slots_centro = 10
			
		# 3. Instancia sempre o número exato de molduras
		for i in range(total_slots_centro):
			if cena_moldura_slot:
				var moldura = cena_moldura_slot.instantiate()
				center_peca_grid.add_child(moldura)

				# Se houver uma carta para este índice, ela entra como FILHA da moldura
				if i < cartas_reais_centro.size():
					if cena_carta_pequena:
						var btn_carta = cena_carta_pequena.instantiate()

						var container_interno = moldura.get_node("MarginContainer")
						container_interno.add_child(btn_carta)

						if btn_carta.has_method("setup_item"):
							btn_carta.setup_item(cartas_reais_centro[i])

						# Como é apenas exibição visual no centro, deixamos o botão "surdo"
						if btn_carta is BaseButton:
							btn_carta.disabled = true
						btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# 4. Recalcula o tamanho das molduras pra caberem direitinho no GridContainer
		call_deferred("_ajustar_grid_ao_container", center_peca_grid)
		# --- FIM DA ATUALIZAÇÃO DO GRID CENTRAL ---

		if center_peca_slots_hbox:
			for child in center_peca_slots_hbox.get_children():
				child.queue_free()
				
			var slots_usados = 0
			for carta in item.slotsUpgrates:
				if carta != null:
					slots_usados += carta.custoSlotes
					
			if cw_contagem_slots_label:
				cw_contagem_slots_label.text = "Slots (%d/%d)" % [slots_usados, item.quantosSlotes]
					
			for i in range(item.quantosSlotes):
				var icone_bolinha = TextureRect.new()
				icone_bolinha.texture = icone_slot_ocupado if i < slots_usados else icone_slot_livre
				icone_bolinha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icone_bolinha.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icone_bolinha.custom_minimum_size = Vector2(40, 40) 
				center_peca_slots_hbox.add_child(icone_bolinha)
				
		center_action_label.text = "Trocar"

func _clear_center_window() -> void:
	item_em_inspecao = null
	inspecionando_carta_equipada = false
	
	# Troca a visibilidade
	if center_pai_margincontainer: center_pai_margincontainer.visible = false
	if center_plainmsg_vbox: center_plainmsg_vbox.visible = true
	
	# Limpa os dados residuais
	central_nome_label.text = "" 
	central_descricao_label.text = ""
#	if central_arte_rect: central_arte_rect.texture = null
	
	if thumbnail_video_wrapper:
		thumbnail_video_wrapper.visible = false
	if central_video_player:
		central_video_player.paused = false
		central_video_player.stop()
	
	center_action_label.text = "Ação" 
	center_action_label.modulate = Color.WHITE
	center_action_btn.disabled = true

func _update_right_window() -> void:
	if GameState.jogadores.size() == 0: return 
	if current_slot < 1 or current_slot > GameState.jogadores.size(): return 

	var peca_atual = GameState.jogadores[current_slot - 1] 
	
	if is_instance_valid(right_peca_visual) and peca_atual != null:
#		right_peca_visual.show()
		right_peca_visual.setup_peca(peca_atual)
		
	
	if right_nome_label:
		right_nome_label.texto_auto_ajustavel = peca_atual.nome
		
	#if rw_button_texture and rw_button_label:
		#rw_button_texture.visible = true
		#var index_no_time = GameState.jogadores.find(peca_atual)
		#
		#rw_button_label.text = str(index_no_time + 1) if index_no_time != -1 and index_no_time < slot_buttons.size() else " "
			
	var status = _get_status_calculado(peca_atual)
	var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, peca_atual.quantosSlotes]
#	right_window_stats.text = texto_status
	#var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, item.quantosSlotes]
	print (texto_status)
	rw_AP_label.text = "Pontos de Ação   ·   %d AP" % [status.pa]
	rw_forca_label.text = "Força   ·   lvl %d" % peca_atual.level_force#[status.forca]
	rw_RP_label.text = "RP: %d" % (status.pa + peca_atual.level_force + peca_atual.quantosSlotes)
	rw_rank_label.text = str(TeamPlayer.Rank.keys()[peca_atual.estimateRank()])[-1]
	
	

	if right_slots_indicator_hbox:
		for child in right_slots_indicator_hbox.get_children():
			child.queue_free()
			
		var slots_usados = 0
		for carta in peca_atual.slotsUpgrates:
			if carta != null:
				slots_usados += carta.custoSlotes
				
		if rw_contagem_slots_label:
			rw_contagem_slots_label.text = "Slots (%d/%d)" % [slots_usados, peca_atual.quantosSlotes]
				
		for i in range(peca_atual.quantosSlotes):
			var icone_bolinha = TextureRect.new()
			icone_bolinha.texture = icone_slot_ocupado if i < slots_usados else icone_slot_livre
			icone_bolinha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_bolinha.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			#icone_bolinha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
			icone_bolinha.custom_minimum_size = Vector2(40, 40)
			right_slots_indicator_hbox.add_child(icone_bolinha)

# --- INÍCIO DA ATUALIZAÇÃO DO GRID DIREITO COM MOLDURAS FIXAS ---
	for child in right_window_grid.get_children():
		child.queue_free()

	# 1. Filtra apenas as cartas reais equipadas (ignora os nulls da array)
	var cartas_reais_dir = []
	for carta in peca_atual.slotsUpgrates:
		if carta != null:
			cartas_reais_dir.append(carta)

# 2. Define a regra fixa de 8 ou 10 molduras na tela baseada nas cartas EQUIPADAS
	var total_slots_dir = 8
	if cartas_reais_dir.size() > 8:
		total_slots_dir = 10

	# 3. Instancia sempre o número exato de molduras
	for i in range(total_slots_dir):
		if cena_moldura_slot:
			var moldura = cena_moldura_slot.instantiate()
			right_window_grid.add_child(moldura)

			# Se houver uma carta para este índice, ela entra como FILHA da moldura
			if i < cartas_reais_dir.size():
				if cena_carta_pequena:
					var btn_carta = cena_carta_pequena.instantiate()
					
					if btn_carta is BaseButton:
						btn_carta.button_group = grupo_janela_direita
					
					var container_interno = moldura.get_node("MarginContainer")
					container_interno.add_child(btn_carta)
					
					if btn_carta.has_method("setup_item"):
						btn_carta.setup_item(cartas_reais_dir[i])

#					btn_carta.pressed.connect(func(): _inspecionar_item_na_janela_central(cartas_reais_dir[i], true))
					var carta_alvo = cartas_reais_dir[i]
					btn_carta.pressed.connect(func():
						# Se não estiver na aba de cartas, muda para ela
						if current_tab != CategoryTab.CARDS:
							_switch_tab(CategoryTab.CARDS)
						
						# Abre a carta no centro normalmente
						_inspecionar_item_na_janela_central(carta_alvo, true))
					
	# 4. Recalcula o tamanho das molduras pra caberem direitinho no GridContainer
	call_deferred("_ajustar_grid_ao_container", right_window_grid)
# --- FIM DA ATUALIZAÇÃO DO GRID DIREITO ---


# --- SISTEMA DE AÇÕES ---
func _on_center_action_pressed() -> void:
	if item_em_inspecao == null: return
	
	var peca_titular_atual = GameState.jogadores[current_slot - 1]
	
	if item_em_inspecao is TeamPlayer:
		var peca_entrando = item_em_inspecao
		var peca_saindo = peca_titular_atual
		var index_no_array = GameState.jogadores.find(peca_entrando)
		
		if index_no_array != -1:
			GameState.jogadores[current_slot - 1] = peca_entrando
			GameState.jogadores[index_no_array] = peca_saindo
		else:
			var original = Database.pecas_db.get(peca_entrando.id_unico)
			if original == null:
				return
			var nova_peca = original.duplicate(true)
			nova_peca.slotsUpgrates.clear()
			nova_peca.slotsUpgrates.resize(nova_peca.quantosSlotes)
			nova_peca.time = CupManager.myTeam
			
			GameState.jogadores[current_slot - 1] = nova_peca
			GameState.remover_peca(peca_entrando.id_unico)
		
		# =========================================================
		# NOVA LÓGICA: ATUALIZA O NÚMERO DA CAMISA DA PEÇA EQUIPADA
		# =========================================================
		# Pegamos a peça que acabou de ser confirmada no array de titulares
		var peca_que_assumiu_a_vaga = GameState.jogadores[current_slot - 1]
		
		if peca_que_assumiu_a_vaga != null and numero_peca_topbar_escolhida != "":
			# O método .to_int() transforma a String "5" no inteiro 5 de forma segura
			peca_que_assumiu_a_vaga.num_camisa = numero_peca_topbar_escolhida.to_int()
		# =========================================================
		
		_atualizar_nomes_dos_slots()
		_enviar_peca_para_banco(peca_saindo)
		
		_switch_tab(CategoryTab.PIECES)
		_update_right_window()
		_clear_center_window()
		return 

	elif item_em_inspecao is CardResource:
		if inspecionando_carta_equipada:
			_remover_buff_da_peca(peca_titular_atual, item_em_inspecao)
			GameState.adicionar_carta(item_em_inspecao.id_unico)
			inspecionando_carta_equipada = false 
		else:
			if not GameState.tem_carta(item_em_inspecao.id_unico):
				return
			if peca_titular_atual.slotsUpgrates.size() != peca_titular_atual.quantosSlotes:
				peca_titular_atual.slotsUpgrates.resize(peca_titular_atual.quantosSlotes)
				
			var slot_livre = peca_titular_atual.slotsUpgrates.find(null)
			if slot_livre != -1:
				peca_titular_atual.slotsUpgrates[slot_livre] = item_em_inspecao
				GameState.remover_carta(item_em_inspecao.id_unico)
		
		_switch_tab(CategoryTab.CARDS)
		_update_right_window()
		_clear_center_window()
		return


func _enviar_peca_para_banco(peca: TeamPlayer) -> void:
	var tem_cartas := false
	for c in peca.slotsUpgrates:
		if c != null:
			tem_cartas = true
			break
	
	if tem_cartas:
		if not GameState.jogadores.has(peca):
			GameState.jogadores.append(peca)
	else:
		GameState.adicionar_peca(peca.id_unico)
		var idx = GameState.jogadores.find(peca)
		if idx != -1:
			GameState.jogadores.remove_at(idx)


func _remover_buff_da_peca(peca: TeamPlayer, carta: CardResource):
	var index = peca.slotsUpgrates.find(carta)
	if index != -1:
		peca.slotsUpgrates[index] = null
		_reorganizar_slots_da_peca(peca)

func _on_btn_salvar_sair_pressed() -> void:
	SaveManager.save_game()
	
	var num_titulares = mini(slot_buttons.size(), GameState.jogadores.size())
	CupManager.myTeam.mainSquad.clear()
	for i in range(num_titulares):
		CupManager.myTeam.mainSquad.append(GameState.jogadores[i])
	
	CupManager.myTeam.collectedSquad.clear()
	for i in range(num_titulares, GameState.jogadores.size()):
		CupManager.myTeam.collectedSquad.append(GameState.jogadores[i])
	
	var menu = get_parent().get_node_or_null("MainMenu")
	if menu:
		menu.visible = true
		
	queue_free()


# --- UTILIDADES ---
func _get_status_calculado(peca: TeamPlayer) -> Dictionary:
	var f_total = peca.forca if "forca" in peca else 1
	var pa_total = peca.PA if "PA" in peca else 1
	
	for carta in peca.slotsUpgrates:
		if carta != null:
			match carta.tipo_efeito:
				CardResource.TipoEfeito.FORCA:
					f_total += carta.magnitude
				CardResource.TipoEfeito.PA:
					pa_total += carta.magnitude
					
	return {"forca": f_total, "pa": pa_total}

func _gerar_texto_detalhado_carta(carta: CardResource) -> String:
	# 1. A descrição original em itálico
	var texto = ""#"[i]\"" + carta.descricao + "\"[/i]\n\n"
	
	# 2. Tipo da Carta (Passiva ou Ativa) e Custo de PA
	#if carta.is_passiva:
		#texto += "[b]Tipo:[/b] Passiva\n"
	#else:
		#texto += "[b]Tipo:[/b] Ativa [color=orange](Custo: %d PA)[/color]\n" % carta.custo_energia
		
	# 3. Raridade com Cores
	#var nome_raridade = CardResource.Raridade.keys()[carta.raridade].capitalize()
	#var cor_raridade = "white"
	#match carta.raridade:
		#CardResource.Raridade.NORMAL: cor_raridade = "gray"
		#CardResource.Raridade.INCOMUN: cor_raridade = "green"
		#CardResource.Raridade.RARA: cor_raridade = "gold"
	#texto += "[b]Raridade:[/b] [color=%s]%s[/color]\n" % [cor_raridade, nome_raridade]
	
	# 4. Efeito e Magnitude (Usa o capitalize para tirar o "_" do enum e deixar bonito)
	#var nome_efeito = CardResource.TipoEfeito.keys()[carta.tipo_efeito].capitalize()
	#texto += "[b]Efeito:[/b] %s" % nome_efeito
	#if carta.magnitude > 0:
		#texto += " [color=cyan](Magnitude: %d)[/color]\n" % carta.magnitude
	#else:
#		texto += "\n"
#	texto += "\n"
		
	# 5. Alvo
	#var nome_alvo = CardResource.TipoAlvo.keys()[carta.tipo_alvo].capitalize()
	#texto += "[b]Alvo:[/b] %s\n" % nome_alvo
	
	# 6. Duração (só exibe se for maior que 0)
	#if carta.duracao > 0:
		#texto += "[b]Duração:[/b] %d turno(s)" % carta.duracao
#	if carta.descricao:
	texto = carta.descricao
	
	return texto

# --- ATUALIZAÇÃO DOS NOMES E VISUAIS DOS SLOTS ---
func _atualizar_nomes_dos_slots() -> void:
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		
		# Procura os nós filhos exatos dentro do botão
		var label_nome = btn.get_node_or_null("Nome")
		var label_numero = btn.get_node_or_null("Numero") 
		
		var peca_no_slot: TeamPlayer = null
		
		# Verifica se existe uma peça equipada para esse slot no momento
		if i < GameState.jogadores.size() and GameState.jogadores[i] != null:
			peca_no_slot = GameState.jogadores[i]
			
		if peca_no_slot != null:
			if label_nome: 
				label_nome.text = peca_no_slot.nome
				
			# =========================================================
			# PEGA O NÚMERO DO BOTÃO E SALVA NA PEÇA
			# =========================================================
			if label_numero and label_numero.text.is_valid_int():
				peca_no_slot.num_camisa = label_numero.text.to_int()
			# =========================================================
				
			# Atualiza o visual da PecaMenuUI correspondente ao slot
			if i < top_slots_visuais.size() and is_instance_valid(top_slots_visuais[i]):
				top_slots_visuais[i].show()
				top_slots_visuais[i].setup_peca(peca_no_slot)
		else:
			if label_nome: 
				label_nome.text = "" # Deixa em branco caso o slot esteja vazio
				
			# Esconde o visual se não houver peça
			if i < top_slots_visuais.size() and is_instance_valid(top_slots_visuais[i]):
				top_slots_visuais[i].hide()
	
# --- REORGANIZAÇÃO DE SLOTS ---
func _reorganizar_slots_da_peca(peca: TeamPlayer) -> void:
	var cartas_ativas = []

	# 1. Pega apenas as cartas que existem (ignora os buracos/nulls)
	for carta in peca.slotsUpgrates:
		if carta != null:
			cartas_ativas.append(carta)

	# 2. Cria um novo array limpo com o tamanho total de slots da peça
	var array_limpo: Array[CardResource] = []
	array_limpo.resize(peca.quantosSlotes)

	# 3. Coloca as cartas ativas em fila indiana, começando do zero
	for i in range(cartas_ativas.size()):
		array_limpo[i] = cartas_ativas[i]

	# 4. Substitui o array velho e bagunçado pelo novo e organizado!
	peca.slotsUpgrates = array_limpo


# --- LAYOUT RESPONSIVO DOS GRIDS DE CARTAS EQUIPADAS ---
# Recalcula o custom_minimum_size de cada filho do GridContainer
# para que as colunas caibam direitinho na largura do pai,
# encolhendo (ou crescendo) conforme o espaço disponível.
func _ajustar_grid_ao_container(grid: GridContainer) -> void:
	print("ajustar grid")
	if not is_instance_valid(grid):
		return

	# ==========================================
	# REGRA 1: GRID PRINCIPAL (INVENTÁRIO)
	# ==========================================
	if grid == inventory_list:
		# Tenta usar a largura salva (medida com grid vazio) primeiro
		var cols: int = grid.columns if grid.columns > 0 else 4
		var largura_usar: float = 0.0
		
		if _saved_pai_width_pieces > 0.0 or _saved_pai_width_cards > 0.0:
			# Pega a largura salva correspondente à aba atual
			largura_usar = _saved_pai_width_pieces if current_tab == CategoryTab.PIECES else _saved_pai_width_cards
		
		if largura_usar <= 0.0:
			# Fallback: mede o pai agora (sem garantia de precisão)
			var pai = grid.get_parent() as Control
			if not is_instance_valid(pai) or pai.size.x <= 0:
				return
			largura_usar = pai.size.x
		
		var tamanho: int = _tamanho_da_largura(largura_usar, cols)

		for filho in grid.get_children():
			if filho is Control:
				var novo_tamanho = Vector2(tamanho, tamanho) if cols > 1 else Vector2(tamanho, 90)

				if filho.custom_minimum_size != novo_tamanho:
					filho.custom_minimum_size = novo_tamanho

				# Apenas preenche a célula horizontalmente (SIZE_FILL)
			# mas NÃO estica verticalmente (SIZE_SHRINK_BEGIN).
			# Isso evita que itens inchem quando há poucas linhas no grid.
			filho.size_flags_horizontal = Control.SIZE_FILL
			filho.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# ==========================================
	# REGRA 2: GRIDS LATERAIS (CENTRO E DIREITA)
	# ==========================================
	else:
		# Não medimos o pai flexível! Apenas damos um tamanho fixo e 
		# seguro para as moldurinhas de status (ex: 45x45)
		for filho in grid.get_children():
			if filho is Control:
				if filho.custom_minimum_size != tamanho_das_cartas:
					filho.custom_minimum_size = tamanho_das_cartas

				# Removemos o EXPAND para as cartas pararem de empurrar a janela!
				filho.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				filho.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _on_grid_resized(grid: GridContainer) -> void:
	_ajustar_grid_ao_container(grid)

func _abrir_modo_cinema() -> void:
	if not item_em_inspecao is CardResource or item_em_inspecao.video_preview == null:
		return

	# 1. Carrega o vídeo, dá Play e Pausa "em silêncio"
	popup_video_player.stream = item_em_inspecao.video_preview
	popup_video_player.play()
	popup_video_player.paused = true 
	
	# Espera 2 frames pro motor ler o cabeçalho do arquivo .ogv
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 2. Descobre a Resolução Nativa do Vídeo (ex: 1920x1080, 800x600)
	var tamanho_video = Vector2(640, 480) # Tamanho reserva de segurança
	var textura_video = popup_video_player.get_video_texture()
	if textura_video and textura_video.get_size() != Vector2.ZERO:
		tamanho_video = textura_video.get_size()
		
	# 3. Matemática de Limites (Proporção da Tela)
	var tamanho_tela = get_viewport_rect().size
	var margem = 100.0 # Borda de respiro para o vídeo não encostar nas laterais
	var limite_maximo = tamanho_tela - Vector2(margem, margem)
	
	# Calcula o quanto precisamos encolher o vídeo para caber na tela
	var escala_x = limite_maximo.x / tamanho_video.x
	var escala_y = limite_maximo.y / tamanho_video.y
	
	# Pega a MENOR escala. Isso garante que o aspecto original (Aspect Ratio) seja mantido!
	var escala_final = min(escala_x, min(escala_y, 1.0)) 
	
	# O tamanho perfeito calculado em pixels
	var tamanho_final = tamanho_video * escala_final
	
	# 4. Aplica o tamanho na caixa
	video_container.custom_minimum_size = tamanho_final
	video_container.size = tamanho_final
	# Centraliza o pivô da caixa para a animação de Zoom sair do meio perfeito
	video_container.pivot_offset = tamanho_final / 2 
	
	# 5. Configura as posições do Tween
	overlay_video.visible = true
	var centro_do_botao = btn_abrir_video.global_position + (btn_abrir_video.size / 2)
	
	# Ajusta as posições X e Y descontando o tamanho da própria caixa
	var pos_inicial = centro_do_botao - (tamanho_final / 2)
	var pos_centro_tela = (tamanho_tela / 2) - (tamanho_final / 2)
	
	video_container.global_position = pos_inicial
	video_container.scale = Vector2(0.1, 0.1)
	video_container.modulate.a = 0
	fundo_escuro.modulate.a = 0
	
	# 6. Animação
	var tween = create_tween().set_parallel(true)
	tween.tween_property(video_container, "global_position", pos_centro_tela, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(video_container, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(video_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(fundo_escuro, "modulate:a", 1.0, 0.4)
	
	# 7. Solta o Play!
	popup_video_player.paused = false


func _fechar_modo_cinema() -> void:
	# Calcula de volta a posição exata do botão para a janela "ser sugada" por ele
	var centro_do_botao = btn_abrir_video.global_position + (btn_abrir_video.size / 2)
	var pos_alvo = centro_do_botao - (video_container.size / 2)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(video_container, "global_position", pos_alvo, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(video_container, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property(video_container, "modulate:a", 0.0, 0.2)
	tween.tween_property(fundo_escuro, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	overlay_video.visible = false
	popup_video_player.stop()

func _ao_mudar_visibilidade() -> void:
	if not visible:
		return
	
	_atualizar_nomes_dos_slots()
	_atualizar_visual_dos_slots()
	
	# --- MEDIÇÃO: limpa o grid e espera 1 frame para o layout se ajustar ---
	for child in inventory_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Mede a largura REAL do pai (sem influência de conteúdo dos filhos)
	var pai = inventory_list.get_parent() as Control
	if is_instance_valid(pai) and pai.size.x > 0:
		if current_tab == CategoryTab.PIECES:
			_saved_pai_width_pieces = pai.size.x
		else:
			_saved_pai_width_cards = pai.size.x
	
	# Popula a aba atual com o tamanho calculado a partir da largura salva
	_switch_tab(current_tab)
	
	# Ajusta os grids laterais (janelas central e direita)
	_ajustar_grid_ao_container(center_peca_grid)
	_ajustar_grid_ao_container(right_window_grid)

func _atualizar_visual_dos_slots() -> void:
	var tween = create_tween().set_parallel(true)
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.pivot_offset = btn.size / 2.0
		
		var animador: AnimadorHover = null
		for filho in btn.get_children():
			if filho is AnimadorHover:
				animador = filho
				break
		# ----------------------------------
		
		if (i + 1) == current_slot:
			# Botão Titular: Trava o hover e fica grande
			if animador: animador.esta_selecionado = true
			
			tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_SINE)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.15)
			
			if textura_slot_selecionado:
				btn.texture_normal = textura_slot_selecionado
				
		else:
			# Botão Inativo: Destrava o hover e volta ao normal
			if animador: animador.esta_selecionado = false
			
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.15)
			
			if textura_slot_inativo:
				btn.texture_normal = textura_slot_inativo
