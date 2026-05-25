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
@export var insp_nome_label: Label         
@export var insp_rank_label: Label         
@export var insp_arte_rect: TextureRect    

@export_group("Janela de Inspeção - Direita")
@export var contagem_slots_label: Label    
@export var slots_indicator_hbox: HBoxContainer 
@export var equipped_cards_grid: GridContainer  
@export var pontos_acao_label: Label       

@export_group("Ícones")
@export var icone_slot_livre: Texture2D
@export var icone_slot_ocupado: Texture2D

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer 
@export var btn_aceitar: TextureButton             

@export_group("Cenas")
@export var cena_botao_peca: PackedScene    
@export var cena_carta_pequena: PackedScene 

func _ready() -> void:
	_limpar_inspecao()
	btn_aceitar.disabled = true
	btn_aceitar.pressed.connect(_on_btn_aceitar_pressed)

func iniciar_tela_de_recompensa(time_inimigo: Team) -> void:
	time_derrotado = time_inimigo
	self.visible = true
	
	for child in container_opcoes.get_children():
		child.queue_free()
		
	var primeiro_btn: Control = null
	var primeira_peca: TeamPlayer = null
		
	# Varre SEMPRE o mainSquad (Titulares) do time inimigo
	for peca_inimiga in time_derrotado.mainSquad:
		if peca_inimiga != null:
			var btn = _criar_botao_de_opcao(peca_inimiga)
			
			# Guarda a primeira peça válida da lista para auto-selecionar
			if primeiro_btn == null and btn != null:
				primeiro_btn = btn
				primeira_peca = peca_inimiga

	# --- AUTO-CARREGA A PRIMEIRA PEÇA DA LISTA ---
	if primeiro_btn and primeira_peca:
		_selecionar_peca(primeira_peca, primeiro_btn)

func _criar_botao_de_opcao(peca: TeamPlayer) -> Control:
	if not cena_botao_peca: return null
	
	var btn_item = cena_botao_peca.instantiate()
	container_opcoes.add_child(btn_item)
	
	btn_item.set_meta("id_peca", peca.id_unico) 
	
	if btn_item.has_method("setup_item"):
		btn_item.setup_item(peca)
		
	var ja_possui = GameState.pecas_desbloqueadas.has(peca.id_unico)
	
	if ja_possui:
		btn_item.modulate = Color(0.6, 0.6, 0.6, 1.0) 
	else:
		btn_item.modulate = Color.WHITE
		
	btn_item.pressed.connect(func(): _selecionar_peca(peca, btn_item))
	return btn_item # Retorna o nó criado para a inicialização poder usar

func _selecionar_peca(peca: TeamPlayer, botao_clicado: Control) -> void:
	peca_selecionada = peca
	
	# 1. Atualiza Esquerda (Nome, Arte, Rank)
	insp_nome_label.text = peca.nome
	insp_rank_label.text = str(TeamPlayer.Rank.keys()[peca.rank])
	if peca.foto:
		insp_arte_rect.texture = peca.foto
		
	pontos_acao_label.text = "%d AP" % peca.PA
	
	# 2. Atualiza a Grid de Cartas Equipadas (com a cena quadrada pequena)
	for child in equipped_cards_grid.get_children():
		child.queue_free()

	var slots_usados = 0
	for carta in peca.slotsUpgrates:
		if carta != null:
			slots_usados += carta.custoSlotes
			
			if cena_carta_pequena:
				var btn_carta = cena_carta_pequena.instantiate()
				equipped_cards_grid.add_child(btn_carta)
				
				if btn_carta.has_method("setup_item"):
					btn_carta.setup_item(carta)
					
				if btn_carta is BaseButton:
					btn_carta.disabled = true
				btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
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
			icone_bolinha.custom_minimum_size = Vector2(20, 20)
			slots_indicator_hbox.add_child(icone_bolinha)

	# 4. Feedback Visual de Seleção na lista inferior
	for child in container_opcoes.get_children():
		var id = child.get_meta("id_peca")
		var peca_na_lista_repetida = GameState.pecas_desbloqueadas.has(id)
		child.modulate = Color(0.6, 0.6, 0.6, 1.0) if peca_na_lista_repetida else Color.WHITE
	
	botao_clicado.modulate = Color(0.5, 1.0, 0.5, 1.0) 
	
	# --- INTELIGÊNCIA DO BOTÃO DE AÇÃO ---
	var selecionou_repetida = GameState.pecas_desbloqueadas.has(peca.id_unico)
	var label_do_botao = btn_aceitar.get_node_or_null("Aceitar_Label")
	
	if label_do_botao:
		if selecionou_repetida:
			label_do_botao.text = "Pegar Cartas"
		else:
			label_do_botao.text = "Aceitar"
			
	btn_aceitar.disabled = false

func _on_btn_aceitar_pressed() -> void:
	if peca_selecionada == null: return
	
	var ja_possui = GameState.pecas_desbloqueadas.has(peca_selecionada.id_unico)
	
	if not ja_possui:
		print("🎁 Recompensa: Peça Inédita + Cartas!")
		var nova_peca = peca_selecionada.duplicate(true)
		nova_peca.time = CupManager.myTeam 
		
		GameState.jogadores.append(nova_peca)
		GameState.pecas_desbloqueadas.append(nova_peca.id_unico)
		
		for carta in nova_peca.slotsUpgrates:
			if carta != null and not GameState.cartas_desbloqueadas.has(carta.id_unico):
				GameState.cartas_desbloqueadas.append(carta.id_unico)
				
	else:
		print("🃏 Recompensa: Peça Repetida! Pegando apenas as cartas.")
		for carta in peca_selecionada.slotsUpgrates:
			if carta != null and not GameState.cartas_desbloqueadas.has(carta.id_unico):
				GameState.cartas_desbloqueadas.append(carta.id_unico)
	
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


func _on_teste_button_pressed() -> void:
	# Como você vai ser o seu próprio inimigo, o jogo vai detectar 
	# que você tem 100% das peças e acionar o "Pegar Cartas"!
	iniciar_tela_de_recompensa(CupManager.myTeam)


func _on_teste_button_2_pressed() -> void:
	# 1. Carrega as peças físicas do save
	GameState.jogadores = SaveManager.load_game()
	
	# 2. O ELO PERDIDO: Sincroniza a lista de IDs desbloqueados!
	GameState.pecas_desbloqueadas.clear()
	for peca in GameState.jogadores:
		if peca != null and not GameState.pecas_desbloqueadas.has(peca.id_unico):
			GameState.pecas_desbloqueadas.append(peca.id_unico)
			
	print("Save carregado! Você possui ", GameState.pecas_desbloqueadas.size(), " peças.")
