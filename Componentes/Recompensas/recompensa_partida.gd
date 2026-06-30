extends Control

## Sinal emitido quando o jogador coleta a recompensa e a tela vai fechar.
## O MatchState aguarda (await) este sinal para avançar o torneio e resetar a partida.
signal recompensa_coletada

# --- VARIÁVEIS DE ESTADO ---
var peca_selecionada: TeamPlayer = null
var time_derrotado: Team = null
var grupo_recompensa := ButtonGroup.new()

# --- REFERÊNCIAS DE NÓS (Mapeadas para a sua imagem) ---
@export_group("Janela de Inspeção - Esquerda")
@export var insp_nome_label: Label         
@export var insp_rank_label: Label         
#@export var insp_arte_rect: TextureRect
@export var insp_peca_visual: PecaMenuUI   
@export var contagem_slots_label: Label
@export var slots_indicator_hbox: HBoxContainer
@export var pontos_acao_label: Label
@export var forca_label: Label
@export var rp_label: Label

@export_group("Janela de Inspeção - Direita")
@export var equipped_cards_grid: GridContainer

@export_group("Ícones")
@export var icone_slot_livre: Texture2D
@export var icone_slot_ocupado: Texture2D
@export var icone_slot_minimum_size:= Vector2(50, 50)

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer 
@export var btn_aceitar: TextureButton             

@export_group("Cenas")
@export var cena_botao_peca: PackedScene
@export var cena_carta_pequena: PackedScene
@export var cena_carta_bem_pequena: PackedScene
@export var cena_moldura_slot: PackedScene
@export var tamanho_das_cartas:= Vector2(100, 100)

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
		primeiro_btn.button_pressed = true
		_selecionar_peca(primeira_peca, primeiro_btn)

func _criar_botao_de_opcao(peca: TeamPlayer) -> Control:
	if not cena_botao_peca: return null
	
	var btn_item = cena_botao_peca.instantiate()
	btn_item.button_group = grupo_recompensa
	container_opcoes.add_child(btn_item)
	btn_item.size_flags_vertical = Control.SIZE_EXPAND_FILL #| Control.SIZE_SHRINK_CENTER
	btn_item.set_meta("id_peca", peca.id_unico) 
	
	if btn_item.has_method("setup_item"):
		btn_item.setup_item(peca)
		
#	var ja_possui = GameState.tem_peca(peca.id_unico)
	
#	if ja_possui:
#		btn_item.modulate = Color(0.6, 0.6, 0.6, 1.0) 
#	else:
#		btn_item.modulate = Color.WHITE
		
	btn_item.pressed.connect(func(): _selecionar_peca(peca, btn_item))
	return btn_item # Retorna o nó criado para a inicialização poder usar

func _selecionar_peca(peca: TeamPlayer, _botao_clicado: Control) -> void:
	peca_selecionada = peca
	var status = _get_status_calculado(peca)
	# 1. Atualiza Esquerda (Nome, Arte, Rank)
	insp_nome_label.text = peca.nome
	insp_rank_label.text = str(TeamPlayer.Rank.keys()[peca.rank])
	#if peca.foto:
		#insp_arte_rect.texture = peca.foto
	if is_instance_valid(insp_peca_visual):
#		insp_peca_visual.show() # Garante que está visível
		insp_peca_visual.setup_peca(peca)
	
	pontos_acao_label.text = "Pontos de Ação   ·   %d AP" % [status.pa]
	forca_label.text = "Força   ·   lvl %d" % status.forca#[status.forca]
	rp_label.text = "RP: %d" % (status.pa + status.forca + peca.quantosSlotes)
	#"RP: %d" % ([status.pa_total] + [status.forca] + [peca.quantosSlotes])
	
	# 2. Atualiza a Grid de Cartas Equipadas (Usando Molduras)
	for child in equipped_cards_grid.get_children():
		child.queue_free()

	# ====================================================================
	# 2.1 FILTRA AS CARTAS E CONTA OS SLOTS USADOS
	# ====================================================================
	var cartas_reais = []
	var slots_usados = 0
	for carta in peca.slotsUpgrates:
		if carta != null:
			cartas_reais.append(carta)
			slots_usados += carta.custoSlotes # Importante para a Etapa 3 não quebrar!

	# ====================================================================
	# 2.2 DEFINE A REGRA FIXA DE 8 OU 10 MOLDURAS
	# ====================================================================
	var total_slots = 8
	if cartas_reais.size() > 8:
		total_slots = 10

	# ====================================================================
	# 2.3 INSTANCIA AS MOLDURAS E AS CARTAS DENTRO DELAS
	# ====================================================================
	for i in range(total_slots):
		if cena_moldura_slot:
			var moldura = cena_moldura_slot.instantiate()
			# Aplica o tamanho base exportado
			moldura.custom_minimum_size = tamanho_das_cartas
			equipped_cards_grid.add_child(moldura)

			# Se houver uma carta real para este índice, ela entra como FILHA da moldura
			if i < cartas_reais.size():
				if cena_carta_pequena: # Ou cena_carta_pequena, dependendo do que preferir
					var btn_carta = cena_carta_pequena.instantiate()
					
					# Pega o MarginContainer de dentro da moldura para ancorar a carta
					var container_interno = moldura.get_node_or_null("MarginContainer")
					if container_interno:
						container_interno.add_child(btn_carta)
					else:
						moldura.add_child(btn_carta) # Fallback caso a moldura mude
					
					if btn_carta.has_method("setup_item"):
						btn_carta.setup_item(cartas_reais[i])
						
					# Como é apenas exibição visual, deixamos a carta inerte (surda para cliques)
					if btn_carta is BaseButton:
						btn_carta.disabled = true
					btn_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# --------------------------------------------------------------------------
	# --------------------------------------------------------------------------
			
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
			icone_bolinha.custom_minimum_size = icone_slot_minimum_size
			slots_indicator_hbox.add_child(icone_bolinha)

	# 4. Feedback Visual de Seleção na lista inferior
	#for child in container_opcoes.get_children():
		#var id = child.get_meta("id_peca")
		#var peca_na_lista_repetida = GameState.tem_peca(id)
#		child.modulate = Color(0.6, 0.6, 0.6, 1.0) if peca_na_lista_repetida else Color.WHITE
	
	
	# --- INTELIGÊNCIA DO BOTÃO DE AÇÃO ---
	var label_do_botao = btn_aceitar.get_node_or_null("Aceitar_Label")
	
	if label_do_botao:
		label_do_botao.text = "Aceitar"
			
	btn_aceitar.disabled = false

func _on_btn_aceitar_pressed() -> void:
	if peca_selecionada == null: return
	
	var peca = peca_selecionada
	var tem_cartas := false
	for c in peca.slotsUpgrates:
		if c != null:
			tem_cartas = true
			break
	
	if tem_cartas:
		# Peça modificada → guarda individualmente no banco
		print("🎁 Recompensa: Peça com Cartas!")
		var nova_peca = peca.duplicate(true)
		nova_peca.time = CupManager.myTeam
		GameState.jogadores.append(nova_peca)
	else:
		# Peça limpa → incrementa o stack
		print("🎁 Recompensa: +1 Peça para o stack!")
		GameState.adicionar_peca(peca.id_unico)
	
	# Cartas que vieram na peça → incrementa stack de cartas
	for carta in peca.slotsUpgrates:
		if carta != null:
			GameState.adicionar_carta(carta.id_unico)
	
	SaveManager.save_game()
	recompensa_coletada.emit()
	queue_free()

func _limpar_inspecao() -> void:
	peca_selecionada = null
	insp_nome_label.text = "Selecione uma Peça"
#	insp_rank_label.text = ""
#	pontos_acao_label.text = ""
#	insp_arte_rect.texture = null
	if slots_indicator_hbox:
		for child in slots_indicator_hbox.get_children():
			child.queue_free()
	if equipped_cards_grid:
		for child in equipped_cards_grid.get_children():
			child.queue_free()

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
		if peca != null:
			GameState.adicionar_peca(peca.id_unico)
			
	print("Save carregado! Você possui ", GameState.pecas_desbloqueadas.size(), " tipos de peças.")


func _on_teste_button_3_pressed() -> void:
	# 1. Sorteia uma copa aleatória da lista oficial do CupManager
	var copa_aleatoria = CupManager.cupList.pick_random()
	
	# 2. Verifica se a copa tem times e sorteia um time aleatório dela
	if copa_aleatoria and copa_aleatoria.teamPool.size() > 0:
		var time_aleatorio = copa_aleatoria.teamPool.pick_random()
		
		# 3. Inicia a tela de recompensa passando o time sorteado
		iniciar_tela_de_recompensa(time_aleatorio)
		print("Time sorteado para teste: ", time_aleatorio.name)
	else:
		print("Erro: A copa sorteada não possui times na teamPool!")
