extends Control
class_name ElencoMenuManager

enum CategoryTab { PIECES, CARDS }

# --- VARIÁVEIS DE ESTADO ---
var current_slot: int = 1
var current_tab: CategoryTab = CategoryTab.PIECES
var item_em_inspecao: Resource = null 
var inspecionando_carta_equipada: bool = false

var az_ascending := true
var rank_ascending := true
var sort_mode := 0  # 0 = ordem original, 1 = A-Z, 2 = Rank

# --- REFERÊNCIAS DE NÓS (INSPETOR) ---
@export_group("Navegação Superior")
@export var slot_buttons: Array[TextureButton]

@export_group("Texturas dos Slots (Topo)")
@export var textura_slot_selecionado: Texture2D
@export var textura_slot_inativo: Texture2D

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

@export_group("Janela Esquerda")
@export var inventory_list: GridContainer 

@export_group("Janela Central")
@export var central_nome_label: Label
@export var central_descricao_label: RichTextLabel
@export var central_arte_rect: TextureRect
@export var center_action_btn: TextureButton
@export var center_action_label: Label

@export_group("Janela Central - Visual")
@export var center_card_view: VBoxContainer
@export var center_peca_view: VBoxContainer

@export_group("Janela Central - Visibilidade")
@export var center_pai_margincontainer: MarginContainer 
@export var center_plainmsg_vbox: VBoxContainer

@export_group("Janela Central - Elementos da Peça")
@export var center_peca_stats: RichTextLabel
@export var center_peca_grid: GridContainer
@export var cw_button_texture: TextureRect
@export var cw_button_label: Label
@export var center_peca_slots_hbox: HBoxContainer
@export var cw_contagem_slots_label: Label

@export_group("Janela Central - Carta")
@export var slots_que_ocupa_hbox: HBoxContainer
@export var icone_de_slot_textura: Texture2D

@export_group("Janela Direita")
@export var right_nome_label: Label
@export var right_window_stats: RichTextLabel
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


# --- INICIALIZAÇÃO ---
func _ready() -> void:
	_connect_signals()
	_select_slot(1)
	_switch_tab(CategoryTab.PIECES)
	_clear_center_window()
	_atualizar_visuais_dos_filtros()

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
	
	if btn_salvar_sair:
		btn_salvar_sair.pressed.connect(_on_btn_salvar_sair_pressed)


# --- NAVEGAÇÃO E ABAS ---
func _select_slot(slot_index: int) -> void:
	current_slot = slot_index
	
	var tween = create_tween().set_parallel(true)
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.pivot_offset = btn.size / 2.0
		
		if (i + 1) == current_slot:
			# Animação para o botão selecionado (aumenta)
			tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_SINE)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.15)
			
			# Aplica a textura do botão ativo (Ex: O Azul)
			if textura_slot_selecionado:
				btn.texture_normal = textura_slot_selecionado
				
		else:
			# Animação para os botões inativos (tamanho normal)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.15)
			
			# Aplica a textura do botão inativo (Ex: O Vermelho)
			if textura_slot_inativo:
				btn.texture_normal = textura_slot_inativo
			
	_update_right_window()
	GameState.imprimir_status_do_time()
	
	if item_em_inspecao is CardResource and inspecionando_carta_equipada:
		_clear_center_window()
	elif item_em_inspecao is CardResource and not inspecionando_carta_equipada:
		_inspecionar_item_na_janela_central(item_em_inspecao, false)

func _switch_tab(tab: CategoryTab) -> void:
	current_tab = tab
	
	if current_tab == CategoryTab.PIECES:
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
		_popular_lista(pecas_livres)
		
	elif current_tab == CategoryTab.CARDS:
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
		_popular_lista_de_cartas(todas_as_cartas, status_de_uso_das_cartas)


# --- FILTROS DE ORDENAÇÃO ---
func _on_az_filter_pressed() -> void:
	if sort_mode != 1:
		# 1º Clique: Ativa A-Z (Crescente)
		sort_mode = 1
		az_ascending = true
	elif az_ascending == true:
		# 2º Clique: Inverte para Z-A (Decrescente)
		az_ascending = false
	else:
		# 3º Clique: Desliga o filtro e volta à ordem original do save
		sort_mode = 0
		az_ascending = true # Reseta para a próxima vez
		
	_atualizar_visuais_dos_filtros()
	_switch_tab(current_tab)

func _on_rank_filter_pressed() -> void:
	if sort_mode != 2:
		# 1º Clique: Ativa Rank (Melhor pro Pior)
		sort_mode = 2
		rank_ascending = true
	elif rank_ascending == true:
		# 2º Clique: Inverte para Rank (Pior pro Melhor)
		rank_ascending = false
	else:
		# 3º Clique: Desliga o filtro
		sort_mode = 0
		rank_ascending = true # Reseta para a próxima vez
		
	_atualizar_visuais_dos_filtros()
	_switch_tab(current_tab)

func _atualizar_visuais_dos_filtros() -> void:
	# 1. Reseta os dois botões para a cor original (branco puro / sem filtro)
	if az_filter_btn: az_filter_btn.modulate = Color.WHITE
	if rank_filter_btn: rank_filter_btn.modulate = Color.WHITE
	
	# 2. Define as cores dos estados (você pode alterar esses valores depois)
	var cor_estado_1 = Color(0.5, 1.0, 0.5)  # Verde Claro (Crescente)
	var cor_estado_2 = Color(1.0, 0.6, 0.2)  # Laranja (Decrescente)
	
	# 3. Pinta apenas o botão que está ativo
	if sort_mode == 1 and az_filter_btn:
		az_filter_btn.modulate = cor_estado_1 if az_ascending else cor_estado_2
		
	elif sort_mode == 2 and rank_filter_btn:
		rank_filter_btn.modulate = cor_estado_1 if rank_ascending else cor_estado_2

func _apply_sort(array: Array) -> void:
	match sort_mode:
		1: _sort_by_name(array)
		2: _sort_by_rank(array)

func _sort_by_name(array: Array) -> void:
	array.sort_custom(func(a, b):
		var na := ""
		var nb := ""
		if a is TeamPlayer: na = a.nome
		elif a is CardResource: na = a.nome
		if b is TeamPlayer: nb = b.nome
		elif b is CardResource: nb = b.nome
		return na.to_lower() < nb.to_lower() if az_ascending else na.to_lower() > nb.to_lower()
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
func _popular_lista_de_cartas(lista_de_cartas: Array, status_de_uso: Dictionary) -> void:
	for child in inventory_list.get_children():
		child.queue_free()
		
	for carta in lista_de_cartas:
		if cena_item_carta:
			var btn_item = cena_item_carta.instantiate()
			inventory_list.add_child(btn_item)
			
			var usuarios = status_de_uso.get(carta.id_unico, [])
			var esta_em_uso = usuarios.size() > 0
			var nome_do_usuario = usuarios[0] if esta_em_uso else ""
			
			if btn_item.has_method("setup_item"):
				btn_item.setup_item(carta, GameState.quantas_cartas(carta.id_unico))
			
			btn_item.pressed.connect(func(): _inspecionar_item_na_janela_central(carta, false, esta_em_uso, nome_do_usuario))

func _popular_lista(lista_de_itens: Array) -> void:
	for child in inventory_list.get_children():
		child.queue_free()
		
	for item in lista_de_itens:
		var btn_item = null
		
		if item is CardResource and cena_item_carta:
			btn_item = cena_item_carta.instantiate()
		elif item is TeamPlayer and cena_item_peca:
			btn_item = cena_item_peca.instantiate()
			
		if btn_item:
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
	central_nome_label.text = item.nome
	
	if item is CardResource:
		center_card_view.visible = true
		center_peca_view.visible = false
		
		if cw_button_texture:
			cw_button_texture.visible = false 
		
		central_descricao_label.text = _gerar_texto_detalhado_carta(item)
		
		if item.arte:
			central_arte_rect.texture = item.arte
			
		for child in slots_que_ocupa_hbox.get_children():
			child.queue_free()
		for i in range(item.custoSlotes):
			var icone_slot = TextureRect.new()
			icone_slot.texture = icone_de_slot_textura 
			icone_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone_slot.custom_minimum_size = Vector2(25, 25)
			slots_que_ocupa_hbox.add_child(icone_slot)
			
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
		
		if cw_button_texture and cw_button_label:
			cw_button_texture.visible = true
			var index_no_time = GameState.jogadores.find(item)
			
			if index_no_time != -1 and index_no_time < slot_buttons.size():
				cw_button_label.text = str(index_no_time + 1)
			else:
				cw_button_label.text = ""
		
		var status = _get_status_calculado(item)
		var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, item.quantosSlotes]
		center_peca_stats.text = texto_status
		
# --- ATUALIZAÇÃO DO GRID CENTRAL PARA USAR A CENA DE CARTA ---
		for child in center_peca_grid.get_children():
			child.queue_free()
			
		# 1. Lê dinamicamente o tamanho real da sua cena de carta pequena
		var tamanho_carta_centro = Vector2(50, 70) # Tamanho padrão de segurança
		if cena_carta_pequena:
			var btn_fantasma = cena_carta_pequena.instantiate()
			if btn_fantasma is Control and btn_fantasma.custom_minimum_size != Vector2.ZERO:
				tamanho_carta_centro = btn_fantasma.custom_minimum_size
			btn_fantasma.queue_free()
			
		# 2. Popula o grid com o componente real de carta ou slot vazio
		for carta in item.slotsUpgrates:
			if carta != null:
				if cena_carta_pequena:
					var btn_carta = cena_carta_pequena.instantiate()
					center_peca_grid.add_child(btn_carta)
					
					if btn_carta.has_method("setup_item"):
						btn_carta.setup_item(carta)
						
					# Como é apenas exibição visual no centro, deixamos o botão "surdo"
					if btn_carta is BaseButton:
						btn_carta.disabled = true
					btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				var slot_vazio = ColorRect.new()
				slot_vazio.color = Color(0.2, 0.2, 0.2, 0.5)
				slot_vazio.custom_minimum_size = tamanho_carta_centro
				slot_vazio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				slot_vazio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				center_peca_grid.add_child(slot_vazio)
				
		# 3. Matemática da Escala para a janela central (baseada no tamanho real do componente)
		var espaco_colunas_centro = center_peca_grid.get_theme_constant("h_separation")
		var colunas_centro = center_peca_grid.columns if center_peca_grid.columns > 0 else 3
		var largura_necessaria_centro = (tamanho_carta_centro.x * colunas_centro) + (espaco_colunas_centro * (colunas_centro - 1))
		
		var pai_grid_centro = center_peca_grid.get_parent()
		var espaco_max_centro = pai_grid_centro.custom_minimum_size.x
		if espaco_max_centro == 0: espaco_max_centro = pai_grid_centro.size.x
		
		if largura_necessaria_centro > espaco_max_centro and espaco_max_centro > 0:
			var escala = espaco_max_centro / largura_necessaria_centro
			center_peca_grid.scale = Vector2(escala, escala)
		else:
			center_peca_grid.scale = Vector2(1, 1)
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
				icone_bolinha.custom_minimum_size = Vector2(20, 20) 
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
	if central_arte_rect: central_arte_rect.texture = null
	
	center_action_label.text = "Ação" 
	center_action_label.modulate = Color.WHITE
	center_action_btn.disabled = true

func _update_right_window() -> void:
	if GameState.jogadores.size() == 0: return 
	if current_slot < 1 or current_slot > GameState.jogadores.size(): return 

	var peca_atual = GameState.jogadores[current_slot - 1] 

	if right_nome_label:
		right_nome_label.text = peca_atual.nome
		
	if rw_button_texture and rw_button_label:
		rw_button_texture.visible = true
		var index_no_time = GameState.jogadores.find(peca_atual)
		
		rw_button_label.text = str(index_no_time + 1) if index_no_time != -1 and index_no_time < slot_buttons.size() else " "
			
	var status = _get_status_calculado(peca_atual)
	var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, peca_atual.quantosSlotes]
	right_window_stats.text = texto_status

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
			icone_bolinha.custom_minimum_size = Vector2(20, 20)
			right_slots_indicator_hbox.add_child(icone_bolinha)

# --- INÍCIO DA ATUALIZAÇÃO DO GRID DIREITO ---
	for child in right_window_grid.get_children():
		child.queue_free()

	# 1. Lê dinamicamente o tamanho real da sua cena de carta
	var tamanho_carta_dir = Vector2(50, 70) # Tamanho de segurança
	if cena_carta_pequena:
		var btn_fantasma = cena_carta_pequena.instantiate()
		if btn_fantasma is Control and btn_fantasma.custom_minimum_size != Vector2.ZERO:
			tamanho_carta_dir = btn_fantasma.custom_minimum_size
		btn_fantasma.queue_free()

	# 2. Desenha as cartas equipadas e os slots vazios
	for carta in peca_atual.slotsUpgrates:
		if carta != null:
			if cena_carta_pequena:
				var btn_carta = cena_carta_pequena.instantiate()
				right_window_grid.add_child(btn_carta)
				if btn_carta.has_method("setup_item"):
					btn_carta.setup_item(carta)
				btn_carta.pressed.connect(func(): _inspecionar_item_na_janela_central(carta, true))
		else:
			var slot_vazio = ColorRect.new()
			slot_vazio.color = Color(0.2, 0.2, 0.2, 0.5)
			slot_vazio.custom_minimum_size = tamanho_carta_dir
			slot_vazio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			slot_vazio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			right_window_grid.add_child(slot_vazio)

	# 3. Matemática da Escala para não empurrar a UI
	var espaco_colunas_dir = right_window_grid.get_theme_constant("h_separation")
	var colunas_dir = right_window_grid.columns if right_window_grid.columns > 0 else 3
	var largura_necessaria_dir = (tamanho_carta_dir.x * colunas_dir) + (espaco_colunas_dir * (colunas_dir - 1))
	
	var pai_grid_dir = right_window_grid.get_parent()
	var espaco_max_dir = pai_grid_dir.custom_minimum_size.x
	if espaco_max_dir == 0: espaco_max_dir = pai_grid_dir.size.x
	
	if largura_necessaria_dir > espaco_max_dir and espaco_max_dir > 0:
		var escala = espaco_max_dir / largura_necessaria_dir
		right_window_grid.scale = Vector2(escala, escala)
	else:
		right_window_grid.scale = Vector2(1, 1)


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
	var f_total = peca.forca if "forca" in peca else 10
	var pa_total = peca.PA if "PA" in peca else 3
	
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
	var texto = "[i]\"" + carta.descricao + "\"[/i]\n\n"
	
	# 2. Tipo da Carta (Passiva ou Ativa) e Custo de PA
	if carta.is_passiva:
		texto += "[b]Tipo:[/b] Passiva\n"
	else:
		texto += "[b]Tipo:[/b] Ativa [color=orange](Custo: %d PA)[/color]\n" % carta.custo_energia
		
	# 3. Raridade com Cores
	#var nome_raridade = CardResource.Raridade.keys()[carta.raridade].capitalize()
	#var cor_raridade = "white"
	#match carta.raridade:
		#CardResource.Raridade.NORMAL: cor_raridade = "gray"
		#CardResource.Raridade.INCOMUN: cor_raridade = "green"
		#CardResource.Raridade.RARA: cor_raridade = "gold"
	#texto += "[b]Raridade:[/b] [color=%s]%s[/color]\n" % [cor_raridade, nome_raridade]
	
	# 4. Efeito e Magnitude (Usa o capitalize para tirar o "_" do enum e deixar bonito)
	var nome_efeito = CardResource.TipoEfeito.keys()[carta.tipo_efeito].capitalize()
	texto += "[b]Efeito:[/b] %s" % nome_efeito
	if carta.magnitude > 0:
		texto += " [color=cyan](Magnitude: %d)[/color]\n" % carta.magnitude
	else:
		texto += "\n"
		
	# 5. Alvo
	var nome_alvo = CardResource.TipoAlvo.keys()[carta.tipo_alvo].capitalize()
	texto += "[b]Alvo:[/b] %s\n" % nome_alvo
	
	# 6. Duração (só exibe se for maior que 0)
	if carta.duracao > 0:
		texto += "[b]Duração:[/b] %d turno(s)" % carta.duracao
		
	return texto
