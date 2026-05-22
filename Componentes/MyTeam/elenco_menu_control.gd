extends Control
class_name ElencoMenuManager

enum CategoryTab { PIECES, CARDS }

# --- VARIÁVEIS DE ESTADO ---
# Controlam o que está selecionado no momento
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


# --- INICIALIZAÇÃO ---
func _ready() -> void:
	_connect_signals()
	# Define o estado padrão ao abrir o menu
	_select_slot(1)
	_switch_tab(CategoryTab.PIECES)

func _connect_signals() -> void:
	# Conecta os botões do topo (1 a N)
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.pressed.connect(func(): _select_slot(i + 1))
		
	# Conecta botões laterais e de ação
	tab_pieces_btn.pressed.connect(func(): _switch_tab(CategoryTab.PIECES))
	tab_cards_btn.pressed.connect(func(): _switch_tab(CategoryTab.CARDS))
	center_action_btn.pressed.connect(_on_center_action_pressed)
	
	if btn_salvar_sair:
		btn_salvar_sair.pressed.connect(_on_btn_salvar_sair_pressed)


# --- NAVEGAÇÃO E ABAS ---
func _select_slot(slot_index: int) -> void:
	# Atualiza o slot ativo e anima os botões superiores
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
	
	# Ajusta a janela central para não confundir cartas entre slots diferentes
	if item_em_inspecao is CardResource and inspecionando_carta_equipada:
		_clear_center_window()
	elif item_em_inspecao is CardResource and not inspecionando_carta_equipada:
		_inspecionar_item_na_janela_central(item_em_inspecao, false)

func _switch_tab(tab: CategoryTab) -> void:
	# Troca entre inventário de peças reservas e cartas
	current_tab = tab
	
	if current_tab == CategoryTab.PIECES:
		tab_pieces_btn.texture_normal = textura_aba_ativa
		tab_cards_btn.texture_normal = textura_aba_inativa
		
		# Filtra para exibir apenas peças que não estão nos slots titulares
		var num_slots = slot_buttons.size()
		var pecas_livres = []
		if GameState.jogadores.size() > num_slots:
			pecas_livres = GameState.jogadores.slice(num_slots)
		
		inventory_list.columns = 2
		_popular_lista(pecas_livres)
		
	elif current_tab == CategoryTab.CARDS:
		tab_pieces_btn.texture_normal = textura_aba_inativa
		tab_cards_btn.texture_normal = textura_aba_ativa
		
		inventory_list.columns = 1
		
		# Carrega os recursos físicos das cartas usando os IDs do GameState
		var todas_as_cartas = []
		for id_carta in GameState.cartas_desbloqueadas:
			var carta_real = Database.get_carta(id_carta)
			if carta_real != null:
				todas_as_cartas.append(carta_real)
		
		# Rastreia quais cartas já estão equipadas em alguma peça
		var status_de_uso_das_cartas: Dictionary = {} 
		for peca in GameState.jogadores:
			for carta in peca.slotsUpgrates:
				if carta != null:
					if status_de_uso_das_cartas.has(carta.id_unico):
						status_de_uso_das_cartas[carta.id_unico].append(peca.nome)
					else:
						status_de_uso_das_cartas[carta.id_unico] = [peca.nome]
		
		_popular_lista_de_cartas(todas_as_cartas, status_de_uso_das_cartas)


# --- POPULANDO LISTAS (JANELA ESQUERDA) ---
func _popular_lista_de_cartas(lista_de_cartas: Array, status_de_uso: Dictionary) -> void:
	# Função específica para cartas (aplica a trava visual)
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
				btn_item.setup_item(carta)
				
			# Escurece a carta se ela já estiver em uso
			if esta_em_uso:
				btn_item.modulate = Color(0.5, 0.5, 0.5, 1.0) 
			else:
				btn_item.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			btn_item.pressed.connect(func(): _inspecionar_item_na_janela_central(carta, false, esta_em_uso, nome_do_usuario))

func _popular_lista(lista_de_itens: Array) -> void:
	# Função genérica para peças reservas
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
				btn_item.setup_item(item) 
			
			btn_item.pressed.connect(func(): _inspecionar_item_na_janela_central(item))
			

# --- INSPEÇÃO E VISUALIZAÇÃO ---
func _inspecionar_item_na_janela_central(item: Resource, is_equipped_here: bool = false, esta_em_outro_jogador: bool = false, nome_do_outro_jogador: String = ""):
	# Atualiza a janela do meio com os dados do item clicado
	item_em_inspecao = item
	inspecionando_carta_equipada = is_equipped_here
	
	center_action_btn.disabled = false
	center_action_label.modulate = Color.WHITE 
	central_nome_label.text = item.nome
	
	if item is CardResource:
		# Configura a interface para exibir uma CARTA
		center_card_view.visible = true
		center_peca_view.visible = false
		
		if cw_button_texture:
			cw_button_texture.visible = false 
		
		central_descricao_label.text = item.descricao
		if item.arte:
			central_arte_rect.texture = item.arte
			
		# Desenha os ícones de custo de slot da carta
		for child in slots_que_ocupa_hbox.get_children():
			child.queue_free()
		for i in range(item.custoSlotes):
			var icone_slot = TextureRect.new()
			icone_slot.texture = icone_de_slot_textura 
			icone_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone_slot.custom_minimum_size = Vector2(25, 25)
			slots_que_ocupa_hbox.add_child(icone_slot)
			
		# Define o comportamento do botão central (Equipar / Desequipar / Bloqueado)
		if inspecionando_carta_equipada:
			center_action_btn.disabled = false
			center_action_label.text = "Desequipar"
			center_action_label.modulate = Color.WHITE
		elif esta_em_outro_jogador:
			center_action_btn.disabled = true
			center_action_label.text = "Equipado em:\n" + nome_do_outro_jogador
			center_action_label.modulate = Color.YELLOW
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
				center_action_btn.disabled = false
				center_action_label.text = "Equipar"
				center_action_label.modulate = Color.WHITE
				
	elif item is TeamPlayer:
		# Configura a interface para exibir uma PEÇA
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
		
		# Monta a grid de miniaturas das cartas equipadas nesta peça
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
				
		# Desenha as bolinhas de slots livres/ocupados
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
	# Esvazia a janela central para evitar informações fantasmas
	item_em_inspecao = null
	inspecionando_carta_equipada = false
	central_nome_label.text = "Selecione um item"
	central_descricao_label.text = ""
	central_arte_rect.texture = null
	center_action_label.text = "Ação" 
	center_action_label.modulate = Color.WHITE
	center_action_btn.disabled = true

func _update_right_window() -> void:
	# Atualiza o painel da direita com os dados do titular selecionado no topo
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

	# Desenha as bolinhas de slots na janela direita
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

	# Atualiza os botões clicáveis das cartas equipadas
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


# --- SISTEMA DE AÇÕES ---
func _on_center_action_pressed() -> void:
	# Executa a ação baseada no item inspecionado (Trocar Peça / Equipar Carta / Desequipar Carta)
	if item_em_inspecao == null: return
	
	var peca_titular_atual = GameState.jogadores[current_slot - 1]
	
	if item_em_inspecao is TeamPlayer:
		print("Trocando peça do slot ", current_slot)
		
		# Faz o SWAP das posições no array de jogadores
		var index_velho = current_slot - 1
		var index_novo = GameState.jogadores.find(item_em_inspecao)
		
		if index_novo != -1 and index_velho < GameState.jogadores.size():
			var temp = GameState.jogadores[index_velho]
			GameState.jogadores[index_velho] = GameState.jogadores[index_novo]
			GameState.jogadores[index_novo] = temp
			
		_switch_tab(CategoryTab.PIECES)
		_update_right_window()
		_clear_center_window()
		return 

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
		
		_switch_tab(CategoryTab.CARDS)
		_update_right_window()
		_clear_center_window()
		return

func _remover_buff_da_peca(peca: TeamPlayer, carta: CardResource):
	# Limpa o slot específico desequipando a carta
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


# --- UTILIDADES ---
func _get_status_calculado(peca: TeamPlayer) -> Dictionary:
	# Calcula os atributos finais somando base + cartas equipadas
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
