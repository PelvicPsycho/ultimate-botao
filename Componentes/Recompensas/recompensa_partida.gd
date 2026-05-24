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

# --- REFERÊNCIAS DE NÓS ---
@export_group("Janela de Inspeção")
@export var insp_nome_label: Label
@export var insp_rank_label: Label
@export var insp_arte_rect: TextureRect
@export var insp_stats_label: Label
@export var insp_slots_hbox: HBoxContainer
@export var icone_slot_livre: Texture2D # Reutilize os mesmos ícones do menu

@export_group("Opções e Ações")
@export var container_opcoes: HBoxContainer
@export var btn_aceitar: TextureButton

@export_group("Cenas")
@export var cena_botao_peca: PackedScene # Arraste a mesma cena que usamos no menu de elenco

func _ready() -> void:
	# Esconde e reseta a interface inicial
	_limpar_inspecao()
	btn_aceitar.disabled = true
	btn_aceitar.pressed.connect(_on_btn_aceitar_pressed)

# --- FUNÇÃO PRINCIPAL PARA INICIAR A TELA ---
# O MatchScene deve chamar isso e passar CupManager.currentCompetitor quando a partida acabar
func iniciar_tela_de_recompensa(time_inimigo: Team) -> void:
	time_derrotado = time_inimigo
	self.visible = true
	
	# Limpa qualquer botão antigo
	for child in container_opcoes.get_children():
		child.queue_free()
		
	# Cria os 5 botões baseado no time titular do adversário
	for peca_inimiga in time_derrotado.mainSquad:
		if peca_inimiga != null:
			_criar_botao_de_opcao(peca_inimiga)

func _criar_botao_de_opcao(peca: TeamPlayer) -> void:
	if not cena_botao_peca: return
	
	var btn_item = cena_botao_peca.instantiate()
	container_opcoes.add_child(btn_item)
	
	if btn_item.has_method("setup_item"):
		btn_item.setup_item(peca)
		
	# --- TRAVA DE PEÇAS REPETIDAS ---
	var ja_possui = GameState.pecas_desbloqueadas.has(peca.id_unico)
	
	if ja_possui:
		# Deixa o botão cinza e bloqueia clique se o jogador já tiver essa peça
		btn_item.modulate = Color(0.3, 0.3, 0.3, 1.0)
		btn_item.disabled = true
	else:
		btn_item.modulate = Color.WHITE
		# Quando clicar no botão, inspeciona essa peça
		btn_item.pressed.connect(func(): _selecionar_peca(peca, btn_item))

func _selecionar_peca(peca: TeamPlayer, botao_clicado: Control) -> void:
	peca_selecionada = peca
	
	# --- ATUALIZA A JANELA CENTRAL (INSPEÇÃO) ---
	insp_nome_label.text = peca.nome
	insp_rank_label.text = "Rank " + str(TeamPlayer.Rank.keys()[peca.rank])
	if peca.foto:
		insp_arte_rect.texture = peca.foto
		
	# Puxa o status base (sem buffs de cartas do inimigo)
	insp_stats_label.text = "Pontos de Ação • %d AP\nForça Base • %d" % [peca.PA, peca.forca]
	
	# Atualiza bolinhas de slots
	if insp_slots_hbox:
		for child in insp_slots_hbox.get_children():
			child.queue_free()
		for i in range(peca.quantosSlotes):
			var icone = TextureRect.new()
			icone.texture = icone_slot_livre
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.custom_minimum_size = Vector2(20, 20)
			insp_slots_hbox.add_child(icone)

	# --- FEEDBACK VISUAL DO BOTÃO SELECIONADO ---
	# Tira o contorno/brilho de todos os botões e bota só no clicado
	for child in container_opcoes.get_children():
		child.modulate = Color.WHITE if not GameState.pecas_desbloqueadas.has(child.item_resource.id_unico) else Color(0.3, 0.3, 0.3, 1.0)
	
	# Destaque visual no botão selecionado (ex: deixa mais brilhante ou pinta de verde)
	botao_clicado.modulate = Color(0.5, 1.0, 0.5, 1.0) # Tom esverdeado para mostrar seleção

	# Libera o botão de aceitar
	btn_aceitar.disabled = false

func _on_btn_aceitar_pressed() -> void:
	if peca_selecionada == null: return
	
	print("🎁 Recompensa resgatada: ", peca_selecionada.nome)
	
	# 1. Duplica a peça para não afetar o banco de dados original (Muito Importante!)
	var nova_peca = peca_selecionada.duplicate(true)
	
	# 2. Reseta a peça (limpa as cartas que o adversário estava usando)
	nova_peca.slotsUpgrates.clear()
	nova_peca.slotsUpgrates.resize(nova_peca.quantosSlotes)
	#Altera o time da peca para ser o myTeam, nao sei se vamos querer assim ainda
	nova_peca.time = CupManager.myTeam # Transfere a camisa para o seu time
	
	# 3. Adiciona à mochila do jogador no GameState
	GameState.jogadores.append(nova_peca)
	GameState.pecas_desbloqueadas.append(nova_peca.id_unico)
	
	# 4. Salva o jogo imediatamente para não perder a recompensa
	SaveManager.save_game(GameState.jogadores)
	
	# 5. Avisa o CupManager para prosseguir para a próxima partida/fase
	CupManager.nextCompetitor()
	
	# Fecha essa tela (ou avança de cena)
	queue_free()

func _limpar_inspecao() -> void:
	peca_selecionada = null
	insp_nome_label.text = "Selecione uma Peça"
	insp_rank_label.text = ""
	insp_stats_label.text = ""
#	insp_arte_rect.texture = null
	if insp_slots_hbox:
		for child in insp_slots_hbox.get_children():
			child.queue_free()


func _on_teste_button_pressed() -> void:
	iniciar_tela_de_recompensa(CupManager.myTeam)
