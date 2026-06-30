extends Control

## Sinal emitido quando o jogador coleta o pacote do torneio e a tela vai fechar.
signal recompensa_coletada

# --- VARIÁVEIS DE ESTADO (O PACOTE) ---
var pacote_pecas: Array[TeamPlayer] = []
var pacote_cartas: Array[CardResource] = []
var grupo_recompensa := ButtonGroup.new()

@export_group("Animação de Abertura")
# O nó VideoStreamPlayer que vai tocar o baú
@export var video_player: VideoStreamPlayer
# O Panel principal que contém toda a UI (Fundos, VBoxContainer, etc)
@export var tamanho_vazio: Control
@export var video_com_loop: VideoStream
@export var botao_bau: TextureButton

@export_group("Janelas Principais")
@export var inspecao_peca_hbox: Control #Essa vai ser a base sempre ligada pós loot
@export var inspecao_carta_panel: PanelContainer 

@export_group("Inspeção da Peça")
@export var peca_nome_label: Label         # ItemName_Label
@export var peca_rank_label: Label         # PecaRank_Label
#@export var peca_arte_rect: TextureRect    # PecaTexture_TextureRect
@export var insp_peca_visual: PecaMenuUI
@export var peca_rp_label: Label
@export var forca_label: Label
@export var peca_ap_label: Label           # PontosdeAcao_Label
@export var peca_slots_count_label: Label  # ContagemSlots_Label
@export var peca_slots_indicator: HBoxContainer # SlotsIndicator_HBoxContainer da peça
@export var peca_equipped_grid: GridContainer   # EquippedCards_GridContainer

@export_group("Inspeção da Carta")
@export var display_carta: AspectRatioContainer
#@export var carta_arte_rect: TextureRect   # PecaTexture_TextureRect (dentro da InspecaoCarta)
#@export var carta_nome_label: Label        # NomeCarta_Label
@export var carta_descricao_label: Label   # DescricaoCarta_Label
@export var carta_slots_indicator: HBoxContainer # SlotsIndicator_HBoxContainer (dentro da InspecaoCarta)

@export_group("Ícones de Slot")
@export var icone_slot_livre: Texture2D
@export var icone_slot_ocupado: Texture2D
@export var icone_slot_minimum_size:= Vector2(40, 40)

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer # Opcoes_HBoxContainer
@export var btn_menu: TextureButton # Botao Menu

@export_group("Cenas")
@export var cena_botao_peca: PackedScene
@export var cena_carta_pequena: PackedScene
@export var cena_carta_bem_pequena: PackedScene
@export var cena_moldura_slot: PackedScene
@export var tamanho_das_cartas:= Vector2(100, 100)


func _ready() -> void:
	inspecao_peca_hbox.visible = false
	inspecao_carta_panel.visible = false
	tamanho_vazio.visible = true
	botao_bau.visible = true
	btn_menu.visible = false
	container_opcoes.visible = false
	btn_menu.pressed.connect(_on_btn_menu_pressed)
	
	
	if video_player:
		video_player.finished.connect(_on_video_finished)
	

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
			# 1. Pega a peça original do Banco de Dados (Ela sabe o time dela)
			var peca_original = todas_pecas.pick_random()
			
			# 2. Cria o clone
			var peca_sorteada = peca_original.duplicate(true)
			
			# 3. Transfere a camisa do time original para o clone!
			peca_sorteada.time = peca_original.time
			
			# Mantém as cartas que já vêm configuradas na peça
			pacote_pecas.append(peca_sorteada)
			
	# Sorteia 4 Cartas
	for i in range(4):
		if todas_cartas.size() > 0:
			var carta_sorteada = todas_cartas.pick_random()
			pacote_cartas.append(carta_sorteada)
	
	# Debug: insere 2 peças do MyTeam entre as duas sorteadas
	#if _debug_inserir_myteam:
		#_debug_inserir_myteam = false
		#var my_team = CupManager.myTeam
		#if my_team and my_team.mainSquad.size() > 0:
			#var inseridas = 0
			#for peca in my_team.mainSquad:
				#if peca != null and inseridas < 2:
					#var copia = peca.duplicate(true)
					#copia.time = CupManager.myTeam
					#pacote_pecas.insert(1 + inseridas, copia)
					#inseridas += 1
				#if inseridas >= 2:
					#break

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
		
		# O setup_item SAIU daqui!
		
		btn.pressed.connect(func(): _inspecionar_peca(peca, btn))
		botoes_misturados.append({
			"btn": btn,
			"original": Vector2(180.0, 180.0),
			"dado": peca # SALVAMOS A PEÇA AQUI PARA USAR DEPOIS
		})
		
	# 2. Prepara os botões de Carta (Tamanho original 120x120)
	for carta in pacote_cartas:
		if cena_carta_pequena == null:
			continue
		var btn := cena_carta_pequena.instantiate()
		btn.button_group = grupo_recompensa
		
		# O setup_item SAIU daqui!

		btn.pressed.connect(func(): _inspecionar_carta(carta, btn))
		botoes_misturados.append({
			"btn": btn,
			"original": Vector2(120.0, 120.0),
			"dado": carta # SALVAMOS A CARTA AQUI PARA USAR DEPOIS
		})

	# 3. Embaralha a ordem de tudo!
	botoes_misturados.shuffle()

	# 4. Cria a estrutura de 3 camadas para proteger a escala da animação
	for item in botoes_misturados:
		var btn: Button = item["btn"]
		var original: Vector2 = item["original"]
		var dado: Resource = item["dado"] # RECUPERAMOS A INFORMAÇÃO AQUI

		# CAMADA 1: A "Caixa" que avisa o HBoxContainer do tamanho ocupado
		var wrapper := Control.new()
		wrapper.custom_minimum_size = tamanho_unificado
		wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		
		btn.size = original 
		btn.position = Vector2.ZERO
		btn.pivot_offset = original / 2.0 

		# Monta a boneca russa (ADICIONA NA ÁRVORE)
		escalonador.add_child(btn)
		wrapper.add_child(escalonador)
		container_opcoes.add_child(wrapper)
		
		if btn.has_method("setup_item"):
			btn.setup_item(dado)

# --- SISTEMA DE INSPEÇÃO ALTERNADA ---
func _inspecionar_peca(peca: TeamPlayer, _botao_clicado: Control) -> void:
	#inspecao_carta_hbox.visible = false
	tamanho_vazio.visible = false
	video_player.visible = false
	inspecao_peca_hbox.visible = true
	
	var status = _get_status_calculado(peca)
	
	peca_nome_label.text = peca.nome
	peca_rank_label.text = str(TeamPlayer.Rank.keys()[peca.rank])
	#if peca.foto:
		#peca_arte_rect.texture = peca.foto
	if is_instance_valid(insp_peca_visual):
#		insp_peca_visual.show()
		insp_peca_visual.setup_peca(peca)
	
	#peca_ap_label.text = "%d AP" % peca.PA
	peca_ap_label.text = "Pontos de Ação   ·   %d AP" % [status.pa]
	peca_rp_label.text = "RP: %d" % (status.pa + status.forca + peca.quantosSlotes)
	forca_label.text = "Força   ·   lvl %d" % status.forca#[status.forca]
	
	
	
# Limpa a janela de cartas equipadas
	if peca_equipped_grid:
		for child in peca_equipped_grid.get_children():
			child.queue_free()
	
	# ====================================================================
	# 1. FILTRA AS CARTAS E CONTA OS SLOTS USADOS CORRETAMENTE
	# ====================================================================
	var cartas_reais = []
	var slots_usados = 0
	for carta in peca.slotsUpgrates:
		if carta != null:
			cartas_reais.append(carta)
			slots_usados += carta.custoSlotes

	# ====================================================================
	# 2. DEFINE A REGRA FIXA DE 8 OU 10 MOLDURAS
	# ====================================================================
	var total_slots = 8
	if cartas_reais.size() > 8:
		total_slots = 10

	# ====================================================================
	# 3. INSTANCIA AS MOLDURAS E AS CARTAS DENTRO DELAS
	# ====================================================================
	for i in range(total_slots):
		if cena_moldura_slot:
			var moldura = cena_moldura_slot.instantiate()
			moldura.custom_minimum_size = tamanho_das_cartas
			peca_equipped_grid.add_child(moldura)

			# Se houver uma carta para este índice, ela entra como FILHA da moldura
			if i < cartas_reais.size():
				if cena_carta_pequena:
					var btn_carta = cena_carta_pequena.instantiate()
					
					var container_interno = moldura.get_node_or_null("MarginContainer")
					if container_interno:
						container_interno.add_child(btn_carta)
					else:
						moldura.add_child(btn_carta)
					
					if btn_carta.has_method("setup_item"):
						btn_carta.setup_item(cartas_reais[i])
						
					if btn_carta is BaseButton:
						btn_carta.disabled = true
					btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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
	inspecao_carta_panel.visible = true
#	_destacar_botao(_botao_clicado)
	display_carta.setup(carta)

	carta_descricao_label.text = carta.descricao


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


func _get_status_calculado(peca: TeamPlayer) -> Dictionary:
	var f_total = peca.forca if "forca" in peca else 1
	var pa_total = peca.PA if "PA" in peca else 1
	
	for carta in peca.slotsUpgrates:
		if carta != null and carta.is_passiva:
			match carta.tipo_efeito:
				CardResource.TipoEfeito.FORCA:
					f_total += carta.magnitude
				CardResource.TipoEfeito.PA:
					pa_total += carta.magnitude
					
	return {"forca": f_total, "pa": pa_total}


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
	print("Debug: Gerando 6 peças instantaneamente...")
	
	# 1. Limpa as listas atuais e remove os itens antigos da tela
	pacote_pecas.clear() 
	pacote_cartas.clear() 
	for child in container_opcoes.get_children():
		child.queue_free() 
		
	# 2. Gera exatamente 6 peças aleatórias (ignorando cartas)
	var todas_pecas = Database.pecas_db.values()
	for i in range(6):
		if todas_pecas.size() > 0:
			var peca_original = todas_pecas.pick_random()
			var peca_sorteada = peca_original.duplicate(true) 
			
			# Transfere a camisa do time original para o clone!
			peca_sorteada.time = peca_original.time
			
			pacote_pecas.append(peca_sorteada)
			
	# 3. Prepara a UI para aparecer instantaneamente, ignorando o vídeo
	self.visible = true 
	botao_bau.visible = false
	
	if video_player:
		video_player.visible = false
		video_player.stop() # Garante que o áudio/vídeo não continue tocando em segundo plano
		
	# Ativa os fundos e o container das opções
	container_opcoes.visible = true
	btn_menu.visible = true
	
	# Oculta elementos que não devem estar visíveis no momento do sorteio
	tamanho_vazio.visible = false
	inspecao_peca_hbox.visible = false
	#inspecao_carta_panel.visible = false
	
	# 4. Chama a função de desenho para instanciar os botões na hora
	_desenhar_vitrine()


func _on_control_gui_input(event: InputEvent) -> void:
	var clicou_com_mouse = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clicou_com_mouse:
		inspecao_carta_panel.visible = false


func _on_voltar_carta_button_pressed() -> void:
	inspecao_carta_panel.visible = false
