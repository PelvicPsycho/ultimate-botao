extends Control

## No script MatchScene.gd
#
#@export var cena_recompensa: PackedScene
#
#func _jogador_venceu_partida():
	#var tela_rec = cena_recompensa.instantiate()
	#add_child(tela_rec)
	#
	## Pega o time adversário que o CupManager está gerenciando agora
	#tela_rec.iniciar_tela_de_recompensa(CupManager.currentCompetitor)

# --- VARIÁVEIS DE ESTADO ---
var peca_selecionada: TeamPlayer = null
var time_derrotado: Team = null

# --- REFERÊNCIAS DE NÓS (Mapeadas para a sua imagem) ---
@export_group("Janela de Inspeção - Esquerda")
@export var insp_nome_label: Label         # Arraste o ItemName_Label
@export var insp_rank_label: Label         # Arraste o PecaRank_Label
@export var insp_arte_rect: TextureRect    # Arraste o PecaTexture_TextureRect

@export_group("Janela de Inspeção - Direita")
@export var contagem_slots_label: Label    # Arraste o ContagemSlots_Label
@export var slots_indicator_hbox: HBoxContainer # Arraste o SlotsIndicator_HBoxContainer
@export var equipped_cards_grid: GridContainer  # Arraste o EquippedCards_GridContainer
@export var pontos_acao_label: Label       # Arraste o PontosdeAcao_Label

@export_group("Ícones")
@export var icone_slot_livre: Texture2D
@export var icone_slot_ocupado: Texture2D

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer # Arraste o Opcoes_HBoxContainer
@export var btn_aceitar: Button             # Arraste o AceitarButton_Button

@export_group("Cenas")
@export var cena_botao_peca: PackedScene    # Sua cena do botão

func _ready() -> void:
	_limpar_inspecao()
	btn_aceitar.disabled = true
	btn_aceitar.pressed.connect(_on_btn_aceitar_pressed)

func iniciar_tela_de_recompensa(time_inimigo: Team) -> void:
	time_derrotado = time_inimigo
	self.visible = true
	
	for child in container_opcoes.get_children():
		child.queue_free()
		
	# Cria os botões das peças do inimigo
	for peca_inimiga in time_derrotado.mainSquad:
		if peca_inimiga != null:
			_criar_botao_de_opcao(peca_inimiga)

func _criar_botao_de_opcao(peca: TeamPlayer) -> void:
	if not cena_botao_peca: return
	
	var btn_item = cena_botao_peca.instantiate()
	container_opcoes.add_child(btn_item)
	
	# Guarda o ID na memória do botão para facilitar a trava visual depois
	btn_item.set_meta("id_peca", peca.id_unico) 
	
	if btn_item.has_method("setup_item"):
		btn_item.setup_item(peca)
		
	var ja_possui = GameState.pecas_desbloqueadas.has(peca.id_unico)
	
	if ja_possui:
		btn_item.modulate = Color(0.3, 0.3, 0.3, 1.0) # Escurece as repetidas
		btn_item.disabled = true
	else:
		btn_item.modulate = Color.WHITE
		btn_item.pressed.connect(func(): _selecionar_peca(peca, btn_item))

func _selecionar_peca(peca: TeamPlayer, botao_clicado: Control) -> void:
	peca_selecionada = peca
	
	# 1. Atualiza Esquerda (Nome, Arte, Rank)
	insp_nome_label.text = peca.nome
	insp_rank_label.text = "Rank " + str(TeamPlayer.Rank.keys()[peca.rank])
	if peca.foto:
		insp_arte_rect.texture = peca.foto
		
	pontos_acao_label.text = "%d AP" % peca.PA
	
	# 2. Limpa e Atualiza a Grid de Cartas Equipadas (A Mágica Acontece Aqui)
	for child in equipped_cards_grid.get_children():
		child.queue_free()

	var slots_usados = 0
	
	for carta in peca.slotsUpgrates:
		if carta != null:
			slots_usados += carta.custoSlotes
			
			var icone_carta = TextureRect.new()
			icone_carta.texture = carta.arte
			icone_carta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_carta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone_carta.custom_minimum_size = Vector2(40, 60) # Ajuste o tamanho para caber no seu layout
			equipped_cards_grid.add_child(icone_carta)
			
	# 3. Atualiza os Slots (Textos e Bolinhas)
	if contagem_slots_label:
		contagem_slots_label.text = "Slots (%d/%d)" % [slots_usados, peca.quantosSlotes]

	if slots_indicator_hbox:
		for child in slots_indicator_hbox.get_children():
			child.queue_free()
			
		for i in range(peca.quantosSlotes):
			var icone_bolinha = TextureRect.new()
			icone_bolinha.texture = icone_slot_ocupado if i < slots_usados else icone_slot_livre
			icone_bolinha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_bolinha.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone_bolinha.custom_minimum_size = Vector2(15, 15)
			slots_indicator_hbox.add_child(icone_bolinha)

	# 4. Feedback Visual de Seleção no contêiner de baixo
	for child in container_opcoes.get_children():
		var id = child.get_meta("id_peca")
		child.modulate = Color.WHITE if not GameState.pecas_desbloqueadas.has(id) else Color(0.3, 0.3, 0.3, 1.0)
	
	botao_clicado.modulate = Color(0.5, 1.0, 0.5, 1.0) # Fica verdinho para mostrar que selecionou
	btn_aceitar.disabled = false

func _on_btn_aceitar_pressed() -> void:
	if peca_selecionada == null: return
	
	# 1. Duplica a peça para o banco de dados original do time inimigo não ser afetado
	var nova_peca = peca_selecionada.duplicate(true)
	nova_peca.time = CupManager.myTeam # Veste a camisa do seu time
	
	# 2. Adiciona a peça ao inventário
	GameState.jogadores.append(nova_peca)
	GameState.pecas_desbloqueadas.append(nova_peca.id_unico)
	
	# 3. Dá ao jogador as cartas que estavam equipadas na peça inimiga!
	for carta in nova_peca.slotsUpgrates:
		if carta != null:
			# Checa se o jogador já não tem essa carta (para itens únicos)
			if not GameState.cartas_desbloqueadas.has(carta.id_unico):
				GameState.cartas_desbloqueadas.append(carta.id_unico)
	
	# 4. Salva e prossegue
	SaveManager.save_game()
	CupManager.nextCompetitor()
	queue_free()

func _limpar_inspecao() -> void:
	peca_selecionada = null
	insp_nome_label.text = "Selecione uma Peça"
	insp_rank_label.text = ""
	pontos_acao_label.text = ""
	insp_arte_rect.texture = null
	if slots_indicator_hbox:
		for child in slots_indicator_hbox.get_children():
			child.queue_free()
	if equipped_cards_grid:
		for child in equipped_cards_grid.get_children():
			child.queue_free()
