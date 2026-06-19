extends Control

## Sinal emitido quando o jogador coleta o pacote do torneio e a tela vai fechar.
signal recompensa_coletada

# --- VARIÁVEIS DE ESTADO (O PACOTE) ---
var pacote_pecas: Array[TeamPlayer] = []
var pacote_cartas: Array[CardResource] = []
var grupo_recompensa := ButtonGroup.new()
var _debug_inserir_myteam := false

@export_group("Animação de Abertura")
# O nó VideoStreamPlayer que vai tocar o baú
@export var video_player: VideoStreamPlayer
# O Panel principal que contém toda a UI (Fundos, VBoxContainer, etc)
@export var fundo_azul_2: TextureRect
@export var fundo_azul_3: TextureRect
@export var tamanho_vazio: Control
@export var video_com_loop: VideoStream
@export var botao_bau: TextureButton

@export_group("Janelas Principais")
@export var inspecao_peca_hbox: Control
@export var inspecao_carta_hbox: Control

@export_group("Inspeção da Peça")
@export var peca_nome_label: Label         # ItemName_Label
@export var peca_rank_label: Label         # PecaRank_Label
#@export var peca_arte_rect: TextureRect    # PecaTexture_TextureRect
@export var insp_peca_visual: PecaMenuUI
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
@export var icone_slot_minimum_size:= Vector2(50, 50)

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer # Opcoes_HBoxContainer
@export var btn_menu: TextureButton # Botao Menu


@export_group("Cenas")
@export var cena_botao_peca: PackedScene
@export var cena_carta_pequena: PackedScene
@export var cena_carta_bem_pequena: PackedScene 

@export_group("Visual dos Slots Vazios")
## O valor de arredondamento de todos os cantos
@export var raio_dos_cantos: int = 15
## A cor de fundo do espaço vazio (com um pouco de transparência por padrão)
@export var cor_do_slot: Color = Color(0.1, 0.1, 0.1, 0.3) 

var estilo_slot_vazio: StyleBoxFlat


func _ready() -> void:
	fundo_azul_2.visible = false
	fundo_azul_3.visible = false
	inspecao_peca_hbox.visible = false
	inspecao_carta_hbox.visible = false
	tamanho_vazio.visible = true
	botao_bau.visible = true
	btn_menu.visible = false
	container_opcoes.visible = false
	btn_menu.pressed.connect(_on_btn_menu_pressed)
	
	_definir_style_box()
	
	if video_player:
		video_player.finished.connect(_on_video_finished)
	
	# Opcional: Garante que as bordas arredondadas fiquem suaves
#	estilo_slot_vazio.anti_aliasing = true

# O MatchScene ou CupManager vai chamar essa função quando o torneio acabar
func iniciar_tela_de_torneio(_copa_atual: Resource) -> void: # O desenrolar começa aqui
	self.visible = true
	pacote_pecas.clear()
	pacote_cartas.clear()
	
	for child in container_opcoes.get_children():
		child.queue_free()
		
	_gerar_loot_do_torneio()
	
	
	if video_player and video_player.stream:
		video_player.visible = true
#		video_player.play()
		
	else:
		# Fallback de segurança: se não houver vídeo configurado, pula direto pra UI
		_on_video_finished()

func _on_video_finished() -> void: #Tocar video de loop, diminuir tamanho, mostrar Hbox recompensas
	if video_com_loop:
		if video_player.finished.is_connected(_on_video_finished):
			video_player.finished.disconnect(_on_video_finished)
		video_player.stream = video_com_loop
		video_player.loop = true
		video_player.play()
	animar_video_para_pequeno()
		
	# Desenha os botões e a vitrine só agora, com o vídeo concluído


func animar_video_para_pequeno() -> void:
	# 1. (Opcional, mas recomendado) Define o pivô para o centro do vídeo.
	# Assim ele encolhe em direção ao meio, e não em direção ao canto superior esquerdo.
#	video_player.pivot_offset = video_player.size / 2.0
	
	# 2. Cria o Tween
	var tween = create_tween()
	
	# 3. Deixa a animação mais suave (começa rápido e desacelera no final)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# 4. Anima a propriedade "scale" para o tamanho desejado (ex: 30% do tamanho original)
	# O último valor (1.0) é o tempo em segundos que a animação vai durar.
	var escala_final = Vector2(0.6, 0.6) 
	tween.tween_property(video_player, "scale", escala_final, 1.0)
	
	# Se você precisar que ele vá para uma posição específica na tela ao mesmo tempo,
	# você pode animar a posição em paralelo usando parallel():
	# var posicao_final = Vector2(800, 500)
	# tween.parallel().tween_property(video_player, "position", posicao_final, 1.0)
	
	# 5. Conecta o sinal de quando o Tween acabar à sua função
	tween.finished.connect(_on_animacao_video_concluida)


# Função que será chamada exatamente quando o Tween terminar
func _on_animacao_video_concluida() -> void:
	print("O vídeo terminou de encolher e chegou no lugar!")
	
	fundo_azul_2.visible = true
	fundo_azul_3.visible = true
	container_opcoes.visible = true
	btn_menu.visible = true
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
			
			# Mantém as cartas que já vêm configuradas na peça do banco de dados
			
			pacote_pecas.append(peca_sorteada)
			
	# Sorteia 4 Cartas
	for i in range(4):
		if todas_cartas.size() > 0:
			var carta_sorteada = todas_cartas.pick_random()
			pacote_cartas.append(carta_sorteada)
	
	# Debug: insere 2 peças do MyTeam entre as duas sorteadas
	if _debug_inserir_myteam:
		_debug_inserir_myteam = false
		var my_team = CupManager.myTeam
		if my_team and my_team.mainSquad.size() > 0:
			var inseridas = 0
			for peca in my_team.mainSquad:
				if peca != null and inseridas < 2:
					var copia = peca.duplicate(true)
					copia.time = CupManager.myTeam
					pacote_pecas.insert(1 + inseridas, copia)
					inseridas += 1
				if inseridas >= 2:
					break

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

	## 6. Auto-seleciona o primeiro item da vitrine
	#if botoes_misturados.size() > 0:
		## Agora o nosso botão real é o filho do escalonador, que é filho do wrapper
		#var primeiro_botao = botoes_misturados[0]["btn"]
		#primeiro_botao.button_pressed = true
		#primeiro_botao.pressed.emit()

# --- SISTEMA DE INSPEÇÃO ALTERNADA ---
func _inspecionar_peca(peca: TeamPlayer, _botao_clicado: Control) -> void:
	inspecao_carta_hbox.visible = false
	tamanho_vazio.visible = false
	video_player.visible = false
	inspecao_peca_hbox.visible = true
#	_destacar_botao(_botao_clicado)
	
	peca_nome_label.text = peca.nome
	peca_rank_label.text = str(TeamPlayer.Rank.keys()[peca.rank])
	#if peca.foto:
		#peca_arte_rect.texture = peca.foto
	if is_instance_valid(insp_peca_visual):
#		insp_peca_visual.show()
		insp_peca_visual.setup_peca(peca)
	
	peca_ap_label.text = "%d AP" % peca.PA
	
	# Limpa a janela de cartas equipadas
	if peca_equipped_grid:
		for child in peca_equipped_grid.get_children():
			child.queue_free()

	var slots_usados = 0
	
	# 1. Varre as cartas equipadas na peça (1 slot = 1 carta, custo ignorado)
	for carta in peca.slotsUpgrates:
		if carta != null:
			slots_usados += 1
			
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
	
	# Atualiza o texto de contagem de slots (agora usando o valor real de slots_usados)
	if peca_slots_count_label:
		peca_slots_count_label.text = "Slots (%d/%d)" % [slots_usados, peca.quantosSlotes]
		
	# Atualiza o mostrador de bolinhas de slots (preenchidas até slots_usados, vazias depois)
	if peca_slots_indicator:
		for child in peca_slots_indicator.get_children():
			child.queue_free()
		for i in range(peca.quantosSlotes):
			var icone = TextureRect.new()
			icone.texture = icone_slot_ocupado if i < slots_usados else icone_slot_livre
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icone.custom_minimum_size = icone_slot_minimum_size
			peca_slots_indicator.add_child(icone)


func _inspecionar_carta(carta: CardResource, _botao_clicado: Control) -> void:
	inspecao_peca_hbox.visible = false
	tamanho_vazio.visible = false
	video_player.visible = false
	inspecao_carta_hbox.visible = true
#	_destacar_botao(_botao_clicado)
	
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

#func _destacar_botao(_botao_clicado: Control) -> void:
	## Agora nós varremos as caixas wrapper
	#for wrapper in container_opcoes.get_children():
		#if wrapper.get_child_count() > 0:
			## O botão real que precisa ficar branco é o filho do wrapper
			#wrapper.get_child(0).modulate = Color.WHITE
#
	## O botão clicado já é a referência certa que vem pelo Signal
	#_botao_clicado.modulate = Color(0.5, 1.0, 0.5, 1.0)

func _on_botao_bau_texture_button_button_up() -> void: #Iniciar recompensa
	video_player.play()
	botao_bau.visible = false

func _definir_style_box():
	
		# 1. Configura o visual do slot uma única vez ao carregar a cena
	estilo_slot_vazio = StyleBoxFlat.new()
	estilo_slot_vazio.bg_color = cor_do_slot
	
	# 2. Aplica o raio exportado em todos os cantos
	estilo_slot_vazio.corner_radius_top_left = raio_dos_cantos
	estilo_slot_vazio.corner_radius_top_right = raio_dos_cantos
	estilo_slot_vazio.corner_radius_bottom_left = raio_dos_cantos
	estilo_slot_vazio.corner_radius_bottom_right = raio_dos_cantos
	
	# 3. Define a cor da sombra (ex: Preto com 50% de transparência)
	estilo_slot_vazio.shadow_color = Color(0, 0, 0, 0.1)
	
	# 4. Define o tamanho/desfoque da sombra (quanto maior, mais espalhada)
	estilo_slot_vazio.shadow_size = 4 
	
	# 5. Projeta a sombra nos eixos X e Y usando um Vector2
	# Valores positivos empurram para a direita (X) e para baixo (Y)
	estilo_slot_vazio.shadow_offset = Vector2(2, 2)
	
	# --- CONFIGURAÇÃO DA BORDA ---
	
	# 1. Define a espessura da borda em pixels para cada lado
	estilo_slot_vazio.border_width_left = 6
	estilo_slot_vazio.border_width_right =6
	estilo_slot_vazio.border_width_top = 6
	estilo_slot_vazio.border_width_bottom = 6

	# 2. Define a cor da borda (ex: um cinza bem claro ou branco com transparência)
	estilo_slot_vazio.border_color = Color(0.1, 0.1, 0.1, 0.1) 

	# 3. Ativa o "blend"! 
	# Isso faz com que a borda não seja uma linha dura, mas crie um degradê suave para dentro.
	estilo_slot_vazio.border_blend = true
	

# --- AÇÃO FINAL (RESGATE) ---
func _on_btn_menu_pressed() -> void:
	print("🏆 Resgatando Pacote do Torneio!")
	
	# Peças sorteadas → se tiver cartas equipadas, guarda a peça inteira; senão, incrementa stack
	for peca in pacote_pecas:
		var tem_cartas := false
		for carta in peca.slotsUpgrates:
			if carta != null:
				tem_cartas = true
				break
		
		if tem_cartas:
			# Peça modificada → guarda a cópia completa no banco
			print("🎁 Torneio: Peça com Cartas!")
			var nova_peca = peca.duplicate(true)
			nova_peca.time = CupManager.myTeam
			GameState.jogadores.append(nova_peca)
		else:
			# Peça limpa → incrementa o stack
			GameState.adicionar_peca(peca.id_unico)
		
		# Cartas que vieram equipadas na peça → incrementa stack de cartas
		for carta in peca.slotsUpgrates:
			if carta != null:
				GameState.adicionar_carta(carta.id_unico)
	
	# Cartas avulsas sorteadas → incrementa stack
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


func _on_button_pressed() -> void:
	print("teste button 03 - Inserindo peças do MyTeam")
	_debug_inserir_myteam = true
#	iniciar_tela_de_torneio(null)
