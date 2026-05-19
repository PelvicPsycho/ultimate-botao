extends Control
class_name ElencoMenuManager

enum CategoryTab { PIECES, CARDS }

# --- VARIÁVEIS DE ESTADO ---
var current_slot: int = 1
var current_tab: CategoryTab = CategoryTab.PIECES
var item_em_inspecao: Resource = null 
var inspecionando_carta_equipada: bool = false

# --- REFERÊNCIAS DE NÓS (INSPETOR) ---
@export_group("Navegação Superior")
@export var slot_buttons: Array[TextureButton]

@export_group("Menu Lateral")
@export var tab_pieces_btn: TextureButton
@export var tab_cards_btn: TextureButton
@export var textura_aba_ativa: Texture2D 
@export var textura_aba_inativa: Texture2D

@export_group("Menu Lateral - Ações")
@export var btn_salvar_sair: Button

@export_group("Janela Esquerda")
@export var inventory_list: VBoxContainer 

@export_group("Janela Central")
@export var central_nome_label: Label
@export var central_descricao_label: RichTextLabel
@export var central_arte_rect: TextureRect
@export var center_action_btn: TextureButton
@export var center_action_label: Label

@export_group("Janela Central - Visual")
@export var center_card_view: VBoxContainer
@export var center_peca_view: VBoxContainer

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

@export_group("Janela Direita - Slots Visual")
@export var right_slots_indicator_hbox: HBoxContainer
@export var icone_slot_ocupado: Texture2D
@export var icone_slot_livre: Texture2D  

@export_group("Cenas")
@export var cena_item_inventario: PackedScene 

func _ready() -> void:
	_connect_signals()
	# Inicialização padrão
	_select_slot(1)
	_switch_tab(CategoryTab.PIECES)

func _connect_signals() -> void:
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.pressed.connect(func(): _select_slot(i + 1))
		
	tab_pieces_btn.pressed.connect(func(): _switch_tab(CategoryTab.PIECES))
	tab_cards_btn.pressed.connect(func(): _switch_tab(CategoryTab.CARDS))
	
	center_action_btn.pressed.connect(_on_center_action_pressed)
	
	if btn_salvar_sair:
		btn_salvar_sair.pressed.connect(_on_btn_salvar_sair_pressed)

# --- LÓGICA DE NAVEGAÇÃO ---
func _select_slot(slot_index: int) -> void:
	current_slot = slot_index
	
	var tween = create_tween().set_parallel(true)
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.pivot_offset = btn.size / 2.0
		
		if (i + 1) == current_slot:
			tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_SINE)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.15)
		else:
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
			tween.tween_property(btn, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.15)
			
	_update_right_window()
	GameState.imprimir_status_do_time()
	
	# --- INTELIGÊNCIA DA JANELA CENTRAL (CORRIGIDA) ---
	if item_em_inspecao is CardResource and inspecionando_carta_equipada:
		# Se era uma carta equipada no botão anterior, esvazia para evitar confusão visual
		_clear_center_window()
		
	elif item_em_inspecao is CardResource and not inspecionando_carta_equipada:
		# Se é uma carta solta do inventário, apenas atualiza a trava/mecanismo de Equipar
		_inspecionar_item_na_janela_central(item_em_inspecao, false)

func _switch_tab(tab: CategoryTab) -> void:
	current_tab = tab
	
	if current_tab == CategoryTab.PIECES:
		# --- VISUAL ---
		tab_pieces_btn.texture_normal = textura_aba_ativa
		tab_cards_btn.texture_normal = textura_aba_inativa
		
		# --- LÓGICA ---
		if GameState.jogadores.size() > 0:
			_popular_lista(GameState.jogadores)
			
	elif current_tab == CategoryTab.CARDS:
		# --- VISUAL ---
		tab_pieces_btn.texture_normal = textura_aba_inativa
		tab_cards_btn.texture_normal = textura_aba_ativa
		
		# --- LÓGICA ---
		_popular_lista(GameState.inventario_cartas)
		
	# Limpa a janela central sempre que trocar de aba
	_clear_center_window()

# --- FUNÇÃO UNIFICADA DE POPULAR LISTA ---
func _popular_lista(lista_de_itens: Array) -> void:
	# 1. Limpa a lista atual
	for child in inventory_list.get_children():
		child.queue_free()
		
	# 2. Instancia os novos itens
	for item in lista_de_itens:
		var btn_item = cena_item_inventario.instantiate() as InventoryItemButton
		inventory_list.add_child(btn_item)
		
		btn_item.setup_item(item) 
		btn_item.pressed.connect(func(): _inspecionar_item_na_janela_central(item))

# --- INSPEÇÃO NA JANELA CENTRAL ---
func _inspecionar_item_na_janela_central(item: Resource, is_equipped: bool = false):
	item_em_inspecao = item
	inspecionando_carta_equipada = is_equipped
	
	center_action_btn.disabled = false
	center_action_label.modulate = Color.WHITE 
	central_nome_label.text = item.nome
	
	# ==========================================
	# SE O ITEM INSPECIONADO FOR UMA CARTA
	# ==========================================
	if item is CardResource:
		center_card_view.visible = true
		center_peca_view.visible = false
		
		if cw_button_texture:
			cw_button_texture.visible = false 
		
		central_descricao_label.text = item.descricao
		if item.arte:
			central_arte_rect.texture = item.arte
			
		# Limpa e mostra apenas o custo em slots da carta
		for child in slots_que_ocupa_hbox.get_children():
			child.queue_free()
			
		for i in range(item.custoSlotes):
			var icone_slot = TextureRect.new()
			icone_slot.texture = icone_de_slot_textura 
			icone_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone_slot.custom_minimum_size = Vector2(25, 25)
			slots_que_ocupa_hbox.add_child(icone_slot)
			
		# Lógica de Trava de Capacidade de Slots
		if inspecionando_carta_equipada:
			center_action_label.text = "Desequipar"
		else:
			var peca_atual = GameState.jogadores[current_slot - 1]
			var slots_usados = 0
			for carta in peca_atual.slotsUpgrates:
				if carta != null:
					slots_usados += carta.custoSlotes
					
			var slots_livres = peca_atual.quantosSlotes - slots_usados
			
			if item.custoSlotes > slots_livres:
				center_action_btn.disabled = true
				center_action_label.text = "Sem Slots"
				center_action_label.modulate = Color.RED
			else:
				center_action_label.text = "Equipar"
				
	# ==========================================
	# SE O ITEM INSPECIONADO FOR UMA PEÇA
	# ==========================================
	elif item is TeamPlayer:
		center_card_view.visible = false
		center_peca_view.visible = true
		
		if cw_button_texture:
			cw_button_texture.visible = true
			var index_no_time = GameState.jogadores.find(item)
			if index_no_time != -1:
				cw_button_label.text = str(index_no_time + 1)
			else:
				cw_button_label.text = ""
		
		# Exibe os status dinamicamente calculados
		var status = _get_status_calculado(item)
		var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, item.quantosSlotes]
		center_peca_stats.text = texto_status
		
		for child in center_peca_grid.get_children():
			child.queue_free()
			
		for carta in item.slotsUpgrates:
			if carta != null:
				var icone = TextureRect.new()
				icone.texture = carta.arte
				icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icone.custom_minimum_size = Vector2(96, 116)
				center_peca_grid.add_child(icone)
			else:
				var slot_vazio = ColorRect.new()
				slot_vazio.color = Color(0.2, 0.2, 0.2, 0.5)
				slot_vazio.custom_minimum_size = Vector2(90, 110)
				center_peca_grid.add_child(slot_vazio)
				
		# --- ATUALIZAÇÃO VISUAL DOS SLOTS DA PEÇA CENTRAL ---
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
				if i < slots_usados:
					icone_bolinha.texture = icone_slot_ocupado
				else:
					icone_bolinha.texture = icone_slot_livre
					
				icone_bolinha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icone_bolinha.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icone_bolinha.custom_minimum_size = Vector2(20, 20) 
				center_peca_slots_hbox.add_child(icone_bolinha)
				
		center_action_label.text = "Trocar"

func _clear_center_window() -> void:
	item_em_inspecao = null
	inspecionando_carta_equipada = false
	central_nome_label.text = "Selecione um item"
	central_descricao_label.text = ""
	central_arte_rect.texture = null
	center_action_label.text = "Ação" 
	center_action_label.modulate = Color.WHITE
	center_action_btn.disabled = true

func _update_right_window() -> void:
	if GameState.jogadores.size() == 0: return 
	if current_slot < 1 or current_slot > GameState.jogadores.size(): return 

	var peca_atual = GameState.jogadores[current_slot - 1] 

	if right_nome_label:
		right_nome_label.text = peca_atual.nome
		
	var status = _get_status_calculado(peca_atual)
	var texto_status = "Força: %d\nPA: %d\nSlots: %d" % [status.forca, status.pa, peca_atual.quantosSlotes]
	right_window_stats.text = texto_status

	# --- ATUALIZAÇÃO VISUAL DOS SLOTS DA PEÇA DIREITA ---
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
			if i < slots_usados:
				icone_bolinha.texture = icone_slot_ocupado
			else:
				icone_bolinha.texture = icone_slot_livre
				
			icone_bolinha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_bolinha.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone_bolinha.custom_minimum_size = Vector2(20, 20)
			right_slots_indicator_hbox.add_child(icone_bolinha)

	# Atualizar Grid de Miniaturas Equipadas
	for child in right_window_grid.get_children():
		child.queue_free()

	for carta in peca_atual.slotsUpgrates:
		if carta != null:
			var icone_btn = TextureButton.new()
			icone_btn.texture_normal = carta.arte
			icone_btn.ignore_texture_size = true
			icone_btn.stretch_mode = TextureButton.STRETCH_SCALE
			icone_btn.custom_minimum_size = Vector2(50, 70)
			icone_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			icone_btn.pressed.connect(func(): _inspecionar_item_na_janela_central(carta, true))
			right_window_grid.add_child(icone_btn)
		else:
			var slot_vazio = ColorRect.new()
			slot_vazio.color = Color(0.2, 0.2, 0.2, 0.5)
			slot_vazio.custom_minimum_size = Vector2(50, 70)
			right_window_grid.add_child(slot_vazio)

# --- AÇÃO DO BOTÃO CENTRAL ---
func _on_center_action_pressed() -> void:
	if item_em_inspecao == null: return
	
	var peca_titular_atual = GameState.jogadores[current_slot - 1]
	
	if item_em_inspecao is TeamPlayer:
		print("Trocando peça do slot ", current_slot)
		GameState.jogadores[current_slot - 1] = item_em_inspecao
		_switch_tab(CategoryTab.PIECES)

	elif item_em_inspecao is CardResource:
		if inspecionando_carta_equipada:
			print("Desequipando ", item_em_inspecao.nome)
			_remover_buff_da_peca(peca_titular_atual, item_em_inspecao)
			inspecionando_carta_equipada = false 
		else:
			print("Tentando equipar ", item_em_inspecao.nome)
			if peca_titular_atual.slotsUpgrates.size() != peca_titular_atual.quantosSlotes:
				peca_titular_atual.slotsUpgrates.resize(peca_titular_atual.quantosSlotes)
				
			var slot_livre = peca_titular_atual.slotsUpgrates.find(null)
			if slot_livre != -1:
				peca_titular_atual.slotsUpgrates[slot_livre] = item_em_inspecao
		
	_update_right_window()
	_inspecionar_item_na_janela_central(item_em_inspecao, inspecionando_carta_equipada)

func _remover_buff_da_peca(peca: TeamPlayer, carta: CardResource):
	var index = peca.slotsUpgrates.find(carta)
	if index != -1:
		peca.slotsUpgrates[index] = null
		print("Carta desequipada com sucesso no menu.")

func _on_btn_salvar_sair_pressed() -> void:
	print("Salvando o time...")
	SaveManager.save_game(GameState.jogadores)
	
	var menu = get_parent().get_node_or_null("MainMenu")
	if menu:
		menu.visible = true
		
	queue_free()

# --- CALCULADORA DE STATUS DINÂMICO ---
func _get_status_calculado(peca: TeamPlayer) -> Dictionary:
	var f_total = peca.força if "força" in peca else 50
	var pa_total = peca.PA if "PA" in peca else 3
	
	for carta in peca.slotsUpgrates:
		if carta != null:
			match carta.tipo_efeito:
				CardResource.TipoEfeito.FORCA:
					f_total += carta.magnitude
					pa_total -= carta.custo_energia
				CardResource.TipoEfeito.PA:
					pa_total += carta.magnitude
					pa_total -= carta.custo_energia
					
	return {"forca": f_total, "pa": pa_total}
