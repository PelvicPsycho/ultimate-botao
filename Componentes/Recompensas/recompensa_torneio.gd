extends Control

## Sinal emitido quando o jogador coleta o pacote do torneio e a tela vai fechar.
signal recompensa_coletada

# --- VARIÁVEIS DE ESTADO (O PACOTE) ---
var pacote_pecas: Array[TeamPlayer] = []
var pacote_cartas: Array[CardResource] = []
var grupo_recompensa := ButtonGroup.new()

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
@export var cena_carta_bem_pequena: PackedScene 

@export_group("Visual dos Slots Vazios")
## O valor de arredondamento de todos os cantos
@export var raio_dos_cantos: int = 15
## A cor de fundo do espaço vazio (com um pouco de transparência por padrão)
@export var cor_do_slot: Color = Color(0.1, 0.1, 0.1, 0.5) 

var estilo_slot_vazio: StyleBoxFlat


func _ready() -> void:
	inspecao_peca_hbox.visible = false
	inspecao_carta_hbox.visible = false
	btn_aceitar.pressed.connect(_on_btn_aceitar_pressed)
	
		# 1. Configura o visual do slot uma única vez ao carregar a cena
	estilo_slot_vazio = StyleBoxFlat.new()
	estilo_slot_vazio.bg_color = cor_do_slot
	
	# 2. Aplica o raio exportado em todos os cantos
	estilo_slot_vazio.corner_radius_top_left = raio_dos_cantos
	estilo_slot_vazio.corner_radius_top_right = raio_dos_cantos
	estilo_slot_vazio.corner_radius_bottom_left = raio_dos_cantos
	estilo_slot_vazio.corner_radius_bottom_right = raio_dos_cantos
	
	# Opcional: Garante que as bordas arredondadas fiquem suaves
#	estilo_slot_vazio.anti_aliasing = true

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
	var tamanho_unificado := Vector2(150.0, 150.0) # Tamanho final que vai aparecer na tela

	# 1. Prepara os botões de Peça (Tamanho original 180x180)
	for peca in pacote_pecas:
		if cena_botao_peca == null:
			continue
		var btn := cena_botao_peca.instantiate()
		btn.button_group = grupo_recompensa
		if btn.has_method("setup_item"):
			btn.setup_item(peca)

		btn.pressed.connect(func(): _inspecionar_peca(peca, btn))
		botoes_misturados.append({
			"btn": btn,
			"original": Vector2(180.0, 180.0),
		})
		

	# 2. Prepara os botões de Carta (Tamanho original 120x120)
	for carta in pacote_cartas:
		if cena_carta_pequena == null:
			continue
		var btn := cena_carta_pequena.instantiate()
		btn.button_group = grupo_recompensa
		if btn.has_method("setup_item"):
			btn.setup_item(carta)

		btn.pressed.connect(func(): _inspecionar_carta(carta, btn))
		botoes_misturados.append({
			"btn": btn,
			"original": Vector2(120.0, 120.0),
		})

	# 3. Embaralha a ordem de tudo!
	botoes_misturados.shuffle()

	# 4. Cria a estrutura de 3 camadas para proteger a escala da animação
	for item in botoes_misturados:
		var btn: Button = item["btn"]
		var original: Vector2 = item["original"]

		# CAMADA 1: A "Caixa" que avisa o HBoxContainer do tamanho ocupado
		var wrapper := Control.new()
		wrapper.custom_minimum_size = tamanho_unificado
		wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# IMPORTANTE: Garante que a animação possa vazar da caixa sem ser cortada
		wrapper.clip_contents = false 

		# Calcula a escala matemática
		var escala := Vector2.ONE
		if original.x > 0.0 and original.y > 0.0:
			escala = tamanho_unificado / original

		# CAMADA 2: O "Escalonador" invisível que aplica a matemática
		var escalonador := Control.new()
		escalonador.scale = escala
		escalonador.position = Vector2.ZERO

		# CAMADA 3: O seu Botão Real
		btn.anchor_left = 0.0
		btn.anchor_top = 0.0
		btn.anchor_right = 0.0
		btn.anchor_bottom = 0.0
		btn.offset_left = 0.0
		btn.offset_top = 0.0
		btn.offset_right = 0.0
		btn.offset_bottom = 0.0
		
		# Ele volta a ter exatamente o tamanho que tem lá no arquivo .tscn
		btn.size = original 
		btn.position = Vector2.ZERO
		
		# Coloca o pivô do botão bem no meio dele! 
		# Assim, quando o seu Hover animar a escala, o botão cresce a partir do centro.
		btn.pivot_offset = original / 2.0 

		# Monta a boneca russa
		escalonador.add_child(btn)
		wrapper.add_child(escalonador)
		container_opcoes.add_child(wrapper)

	# 6. Auto-seleciona o primeiro item da vitrine
	if botoes_misturados.size() > 0:
		# Agora o nosso botão real é o filho do escalonador, que é filho do wrapper
		var primeiro_botao = botoes_misturados[0]["btn"]
		primeiro_botao.button_pressed = true
		primeiro_botao.pressed.emit()

# --- SISTEMA DE INSPEÇÃO ALTERNADA ---
func _inspecionar_peca(peca: TeamPlayer, botao_clicado: Control) -> void:
	inspecao_carta_hbox.visible = false
	inspecao_peca_hbox.visible = true
#	_destacar_botao(botao_clicado)
	
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
			
			if cena_carta_bem_pequena:
				var btn_carta = cena_carta_bem_pequena.instantiate()
				peca_equipped_grid.add_child(btn_carta)
				if btn_carta.has_method("setup_item"):
					btn_carta.setup_item(carta)
				if btn_carta is BaseButton:
					btn_carta.disabled = true
				btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- CALCULA O TAMANHO DOS SLOTS ---
	var tamanho_slot := Vector2(100, 100)
	if cena_carta_bem_pequena:
		var ghost = cena_carta_bem_pequena.instantiate()
		if ghost is Control and ghost.custom_minimum_size.y > 0:
			tamanho_slot = ghost.custom_minimum_size
		ghost.queue_free()
	
	# --- CRIA E ADICIONA OS SLOTS VAZIOS COM PANEL ---
	var slots_livres = peca.quantosSlotes - slots_usados
	for i in range(slots_livres):
		var slot_vazio = Panel.new()
		slot_vazio.custom_minimum_size = tamanho_slot
		slot_vazio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_vazio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot_vazio.add_theme_stylebox_override("panel", estilo_slot_vazio)
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
#	_destacar_botao(botao_clicado)
	
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

#func _destacar_botao(botao_clicado: Control) -> void:
	## Agora nós varremos as caixas wrapper
	#for wrapper in container_opcoes.get_children():
		#if wrapper.get_child_count() > 0:
			## O botão real que precisa ficar branco é o filho do wrapper
			#wrapper.get_child(0).modulate = Color.WHITE
#
	## O botão clicado já é a referência certa que vem pelo Signal
	#botao_clicado.modulate = Color(0.5, 1.0, 0.5, 1.0)

# --- AÇÃO FINAL (RESGATE) ---
func _on_btn_aceitar_pressed() -> void:
	print("🏆 Resgatando Pacote do Torneio!")
	
	# Peças sorteadas (sempre sem cartas) → incrementa stack
	for peca in pacote_pecas:
		GameState.adicionar_peca(peca.id_unico)
	
	# Cartas sorteadas → incrementa stack
	for carta in pacote_cartas:
		GameState.adicionar_carta(carta.id_unico)
	
	SaveManager.save_game()
	recompensa_coletada.emit()
	queue_free()

func _on_teste_button_pressed() -> void:
	print("teste button 01")
	iniciar_tela_de_torneio(null)
	pass


func _on_teste_button_2_pressed() -> void:
	print ("teste button 02")
	# 1. Carrega as peças físicas e suas cartas equipadas do save
	GameState.jogadores = SaveManager.load_game()
	
	# 2. Limpa as memórias antigas de IDs
	GameState.pecas_desbloqueadas.clear()
	GameState.cartas_desbloqueadas.clear()
	
	# 3. Sincroniza a lista de IDs (Tanto de Peças quanto de Cartas!)
	for peca in GameState.jogadores:
		if peca != null:
			GameState.adicionar_peca(peca.id_unico)
			for carta in peca.slotsUpgrates:
				if carta != null:
					GameState.adicionar_carta(carta.id_unico)
					
	# Força o CupManager a ler o GameState de novo para aplicar as cartas no myTeam
	if CupManager.has_method("_sync_main_squad_from_gamestate"):
		CupManager._sync_main_squad_from_gamestate()
		
	print("✔ Save carregado! Peças: ", GameState.pecas_desbloqueadas.size(), " | Cartas: ", GameState.cartas_desbloqueadas.size())
