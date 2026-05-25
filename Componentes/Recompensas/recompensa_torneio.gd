extends Control

# --- VARIÁVEIS DE ESTADO (O PACOTE) ---
var pacote_pecas: Array[TeamPlayer] = []
var pacote_cartas: Array[CardResource] = []

# --- REFERÊNCIAS DE NÓS (Baseado nas suas imagens) ---
@export_group("Janelas Principais")
@export var inspecao_peca_hbox: Control
@export var inspecao_carta_hbox: Control

@export_group("Inspeção da Peça")
@export var peca_nome_label: Label         # ItemName_Label
@export var peca_rank_label: Label         # PecaRank_Label
@export var peca_arte_rect: TextureRect    # PecaTexture_TextureRect
@export var peca_ap_label: Label           # PontosdeAcao_Label
@export var peca_slots_count_label: Label  # ContagemSlots_Label
@export var peca_slots_indicator: HBoxContainer # SlotsIndicator_HBoxContainer da peça
@export var peca_equipped_grid: GridContainer   # EquippedCards_GridContainer

@export_group("Inspeção da Carta")
@export var carta_arte_rect: TextureRect   # PecaTexture_TextureRect (dentro da InspecaoCarta)
@export var carta_nome_label: Label        # NomeCarta_Label
@export var carta_descricao_label: Label   # DescricaoCarta_Label
@export var carta_slots_indicator: HBoxContainer # SlotsIndicator_HBoxContainer (dentro da InspecaoCarta)

@export_group("Ícones de Slot")
@export var icone_slot_livre: Texture2D
@export var icone_slot_ocupado: Texture2D

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer # Opcoes_HBoxContainer
@export var btn_aceitar: TextureButton             # AceitarButton_Button


@export_group("Cenas")
@export var cena_botao_peca: PackedScene
@export var cena_carta_pequena: PackedScene

func _ready() -> void:
	inspecao_peca_hbox.visible = false
	inspecao_carta_hbox.visible = false
	btn_aceitar.pressed.connect(_on_btn_aceitar_pressed)

# O MatchScene ou CupManager vai chamar essa função quando o torneio acabar
func iniciar_tela_de_torneio(copa_atual: Resource) -> void: # O desenrolar começa aqui
	self.visible = true
	pacote_pecas.clear()
	pacote_cartas.clear()
	
	for child in container_opcoes.get_children():
		child.queue_free()
		
	_gerar_loot_do_torneio()
	_desenhar_vitrine()
	

# --- LÓGICA DE SORTEIO ---
func _gerar_loot_do_torneio() -> void:
	var todas_pecas = Database.pecas_db.values()
	var todas_cartas = Database.cartas_db.values()
	
	# Sorteia 2 Peças
	for i in range(2):
		if todas_pecas.size() > 0:
			var peca_sorteada = todas_pecas.pick_random().duplicate(true)
			peca_sorteada.time = CupManager.myTeam 
			
			# Limpa qualquer lixo e deixa a mochila zerada com o tamanho exato de slots
			peca_sorteada.slotsUpgrates.clear()
			peca_sorteada.slotsUpgrates.resize(peca_sorteada.quantosSlotes)
			
			pacote_pecas.append(peca_sorteada)
			
	# Sorteia 4 Cartas
	for i in range(4):
		if todas_cartas.size() > 0:
			var carta_sorteada = todas_cartas.pick_random()
			pacote_cartas.append(carta_sorteada)

# --- DESENHO DA UI ---
func _desenhar_vitrine() -> void:
	var botoes_misturados: Array = []
	
	# 1. Prepara os botões de Peça
	for peca in pacote_pecas:
		if cena_botao_peca:
			var btn = cena_botao_peca.instantiate()
			if btn.has_method("setup_item"):
				btn.setup_item(peca)
			
			btn.pressed.connect(func(): _inspecionar_peca(peca, btn))
			botoes_misturados.append(btn)
			
	# 2. Prepara os botões de Carta
	for carta in pacote_cartas:
		if cena_carta_pequena:
			var btn = cena_carta_pequena.instantiate()
			if btn.has_method("setup_item"):
				btn.setup_item(carta)
				
			btn.pressed.connect(func(): _inspecionar_carta(carta, btn))
			botoes_misturados.append(btn)

	# 3. Embaralha a ordem de tudo!
	botoes_misturados.shuffle()

	# 4. Adiciona os botões já misturados no HBoxContainer
	for btn in botoes_misturados:
		container_opcoes.add_child(btn)

	# 5. Auto-seleciona o primeiro item da vitrine
	if botoes_misturados.size() > 0:
		var primeiro_botao = botoes_misturados[0]
		# Finge um clique no primeiro botão. O botão já sabe se é carta 
		# ou peça e vai abrir a janela correta sozinho!
		primeiro_botao.pressed.emit()

# --- SISTEMA DE INSPEÇÃO ALTERNADA ---
func _inspecionar_peca(peca: TeamPlayer, botao_clicado: Control) -> void:
	inspecao_carta_hbox.visible = false
	inspecao_peca_hbox.visible = true
	_destacar_botao(botao_clicado)
	
	peca_nome_label.text = peca.nome
	peca_rank_label.text = str(TeamPlayer.Rank.keys()[peca.rank])
#	if peca.foto:
#		peca_arte_rect.texture = peca.foto
	peca_ap_label.text = "%d AP" % peca.PA
	
	# Limpa a janela de cartas equipadas
	if peca_equipped_grid:
		for child in peca_equipped_grid.get_children():
			child.queue_free()

	var slots_usados = 0
	
	# 1. Verifica se a peça tem alguma carta (neste caso, não terá)
	for carta in peca.slotsUpgrates:
		if carta != null:
			slots_usados += carta.custoSlotes
			
			if cena_carta_pequena:
				var btn_carta = cena_carta_pequena.instantiate()
				peca_equipped_grid.add_child(btn_carta)
				if btn_carta.has_method("setup_item"):
					btn_carta.setup_item(carta)
				if btn_carta is BaseButton:
					btn_carta.disabled = true
				btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 2. DESENHA OS SLOTS VAZIOS
	var slots_livres = peca.quantosSlotes - slots_usados
	for i in range(slots_livres):
		var slot_vazio = ColorRect.new()
		slot_vazio.color = Color(0.2, 0.2, 0.2, 0.5) 
		slot_vazio.custom_minimum_size = Vector2(40, 60) 
		
		peca_equipped_grid.add_child(slot_vazio)
	
	# Atualiza o texto de contagem de slots
	if peca_slots_count_label:
		peca_slots_count_label.text = "Slots (0/%d)" % peca.quantosSlotes
		
	# Atualiza o mostrador de bolinhas de slots (todas vazias)
	if peca_slots_indicator:
		for child in peca_slots_indicator.get_children():
			child.queue_free()
		for i in range(peca.quantosSlotes):
			var icone = TextureRect.new()
			icone.texture = icone_slot_livre
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			
			# --- AQUI ENTRAM AS DUAS LINHAS NOVAS ---
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			# ----------------------------------------
			
			icone.custom_minimum_size = Vector2(30, 30)
			peca_slots_indicator.add_child(icone)


func _inspecionar_carta(carta: CardResource, botao_clicado: Control) -> void:
	inspecao_peca_hbox.visible = false
	inspecao_carta_hbox.visible = true
	_destacar_botao(botao_clicado)
	
	carta_nome_label.text = carta.nome
	carta_descricao_label.text = carta.descricao
#	if carta.arte:
#		carta_arte_rect.texture = carta.arte
		
	# Desenha as bolinhas de custo da carta
	if carta_slots_indicator:
		for child in carta_slots_indicator.get_children():
			child.queue_free()
		for i in range(carta.custoSlotes):
			var icone = TextureRect.new()
			icone.texture = icone_slot_ocupado
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.custom_minimum_size = Vector2(30, 30)
			carta_slots_indicator.add_child(icone)

func _destacar_botao(botao_clicado: Control) -> void:
	for child in container_opcoes.get_children():
		child.modulate = Color.WHITE
	botao_clicado.modulate = Color(0.5, 1.0, 0.5, 1.0) 

# --- AÇÃO FINAL (RESGATE) ---
func _on_btn_aceitar_pressed() -> void:
	print("🏆 Resgatando Pacote do Torneio!")
	
	# 1. Adiciona as Peças e suas respectivas cartas internas
	for peca in pacote_pecas:
		GameState.jogadores.append(peca)
		if not GameState.pecas_desbloqueadas.has(peca.id_unico):
			GameState.pecas_desbloqueadas.append(peca.id_unico)
			
		# Coleta as cartas equipadas na peça sorteada para a mochila do jogador
		for carta in peca.slotsUpgrates:
			if carta != null and not GameState.cartas_desbloqueadas.has(carta.id_unico):
				GameState.cartas_desbloqueadas.append(carta.id_unico)
			
	# 2. Adiciona as 4 Cartas avulsas normais do pacote
	for carta in pacote_cartas:
		if not GameState.cartas_desbloqueadas.has(carta.id_unico):
			GameState.cartas_desbloqueadas.append(carta.id_unico)
			
	# 3. Salva o progresso
	SaveManager.save_game()
	
	# 4. Continua o jogo / Volta pro menu
	# Ex: get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	queue_free()

func _on_teste_button_pressed() -> void:
	iniciar_tela_de_torneio(null)
	pass


func _on_teste_button_2_pressed() -> void:
	# 1. Carrega as peças físicas e suas cartas equipadas do save
	GameState.jogadores = SaveManager.load_game()
	
	# 2. Limpa as memórias antigas de IDs
	GameState.pecas_desbloqueadas.clear()
	GameState.cartas_desbloqueadas.clear()
	
	# 3. Sincroniza a lista de IDs (Tanto de Peças quanto de Cartas!)
	for peca in GameState.jogadores:
		if peca != null:
			# Registra a peça na lista de bloqueio/desbloqueio
			if not GameState.pecas_desbloqueadas.has(peca.id_unico):
				GameState.pecas_desbloqueadas.append(peca.id_unico)
				
			# Varre a peça e registra as cartas que vieram nela!
			for carta in peca.slotsUpgrates:
				if carta != null and not GameState.cartas_desbloqueadas.has(carta.id_unico):
					GameState.cartas_desbloqueadas.append(carta.id_unico)
					
	# Força o CupManager a ler o GameState de novo para aplicar as cartas no myTeam
	if CupManager.has_method("_sync_main_squad_from_gamestate"):
		CupManager._sync_main_squad_from_gamestate()
		
	print("✔ Save carregado! Peças: ", GameState.pecas_desbloqueadas.size(), " | Cartas: ", GameState.cartas_desbloqueadas.size())
