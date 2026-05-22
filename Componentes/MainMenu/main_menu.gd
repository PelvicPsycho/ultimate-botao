extends Control

@onready var new_game_level: PackedScene = preload("res://MatchScene.tscn")
const MyTeamScene := preload("res://Componentes/MyTeam/elenco_menu_control.tscn") 

func _ready():
	print("=== CONFIGURAÇÕES CARREGADAS ===")
	print("Total de jogadores salvos no GameState: ", GameState.jogadores.size())

	if GameState.jogadores.size() == 0:
		print("Nenhum save encontrado. Carregando time inicial (Grêmio) do Database...")
		_carregar_time_inicial()
	else:
		print("✔ Jogadores carregados do save com sucesso!")
		for j in GameState.jogadores:
			print("\nJogador: ", j.nome)
			for s in j.slotsUpgrates:
				if s:
					print("  - ", s.nome)
				else:
					print("  - [Vazio]")

# Carrega cartas e pecas iniciais se não existe nenhum save
func _carregar_time_inicial():
	var pecas_iniciais: Array = []
	
	# ==========================================
	# 1. CARREGAR AS PEÇAS DO GRÊMIO
	# ==========================================
	for id_peca in Database.pecas_db:
		var peca_original = Database.pecas_db[id_peca]
		
		# Procura peças que tenham um Resource de Time equipado e que o nome seja "Grêmio"
		if peca_original is TeamPlayer and peca_original.time and peca_original.time.name == "Grêmio":
			
			# Faz a cópia para não estragar o arquivo original
			var jogador_copia = peca_original.duplicate(true)
			jogador_copia.slotsUpgrates.resize(jogador_copia.quantosSlotes)
			pecas_iniciais.append(jogador_copia)
			
			# Adiciona aos desbloqueados
			if not GameState.pecas_desbloqueadas.has(jogador_copia.id_unico):
				GameState.pecas_desbloqueadas.append(jogador_copia.id_unico)

	if pecas_iniciais.size() == 0:
		print("ERRO -> Nenhuma peça do Grêmio encontrada no Database!")
	else:
		GameState.jogadores = pecas_iniciais
		print("✔ Time inicial (Grêmio) carregado com sucesso!")


	# ==========================================
	# 2. CARREGAR CARTAS INICIAIS
	# ==========================================
	# Coloque aqui os 'id_unico' exatos das cartas que o jogador começa
	var ids_cartas_iniciais: Array[StringName] = [
		"corre_peao_01", 
		"corre_peao_02",
		"defesa_escudo_01",
		"defesa_escudo_02",
		"bola_leve_01",
		"bola_level_02"
	]
	
	for id_carta in ids_cartas_iniciais:
		# Checa se você não digitou o ID errado e se a carta existe no Database
		if Database.cartas_db.has(id_carta):
			if not GameState.cartas_desbloqueadas.has(id_carta):
				GameState.cartas_desbloqueadas.append(id_carta)
		else:
			print("AVISO -> Carta inicial não encontrada no Database: ", id_carta)
			
	print("✔ Cartas iniciais adicionadas! Total: ", GameState.cartas_desbloqueadas.size())

func _on_team_button_pressed() -> void:
	# Instancia a cena nova e adiciona na tela
	var tela = MyTeamScene.instantiate()
	get_parent().add_child(tela)
	self.visible = false

func _on_continue_button_pressed() -> void:
	favor_me_deletar()

func _on_new_game_button_pressed() -> void:
	if new_game_level != null:
		get_tree().change_scene_to_packed(new_game_level)
	else:
		favor_me_deletar()

func _on_settings_button_pressed() -> void:
	favor_me_deletar()

func favor_me_deletar():
	var label = Label.new()
	label.text = "Error 404"
	var tamanho_fonte = randi_range(10, 64)
	label.add_theme_font_size_override("font_size", tamanho_fonte)
	add_child(label)
	label.pivot_offset = label.size / 2.0
	label.rotation = randf_range(0.0, TAU)

	var tamanho_tela = get_viewport_rect().size
	var pos_x = randf_range(0.0, tamanho_tela.x)
	var pos_y = randf_range(0.0, tamanho_tela.y)
	label.position = Vector2(pos_x, pos_y)

func _on_button_pressed() -> void:
	SaveManager.delete_save()


func _on_add_cartas_button_pressed() -> void:
	
	# Garante que o Database já terminou de carregar os arquivos
	if Database.cartas_db.size() == 0:
		print("Erro: O Database de cartas está vazio ou não foi carregado ainda.")
		return
		
	# Varre todos os IDs únicos que existem cadastrados no jogo
	for id_carta in Database.cartas_db.keys():
		# Só adiciona se o jogador já não tiver ela (evita duplicados)
		if not GameState.cartas_desbloqueadas.has(id_carta):
			GameState.cartas_desbloqueadas.append(id_carta)
