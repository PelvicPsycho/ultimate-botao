extends Control

#@onready var new_game_level: PackedScene = preload("res://MatchScene.tscn")
@onready var new_game_level_2D: PackedScene = preload("res://2D Changes/2D_Scenes/MatchScene2D.tscn")
const MyTeamScene := preload("res://Componentes/MyTeam/elenco_menu_control.tscn") 

func _ready():
	#print("=== CONFIGURAÇÕES CARREGADAS ===")
	#print("Total de jogadores salvos no GameState: ", GameState.jogadores.size())
#
	if GameState.jogadores.size() == 0:
		print("Nenhum save encontrado. Carregando time inicial (My Team) do Database...")
		_carregar_time_inicial()
	#else:
		#print("✔ Jogadores carregados do save com sucesso!")
		#for j in GameState.jogadores:
			#print("\nJogador: ", j.nome)
			#for s in j.slotsUpgrates:
				#if s:
					#print("  - ", s.nome)
				#else:
					#print("  - [Vazio]")
	pass

# Carrega cartas e pecas iniciais se não existe nenhum save
func _carregar_time_inicial():
	var pecas_iniciais: Array = []
	
	# ==========================================
	# 1. CARREGAR AS PEÇAS DO GRÊMIO
	# ==========================================
	for id_peca in Database.pecas_db:
		var peca_original = Database.pecas_db[id_peca]
		
		# Procura peças que tenham um Resource de Time equipado e que o nome seja "Grêmio"
		if peca_original is TeamPlayer and peca_original.time and peca_original.time.name == "My Team":
			
			# Faz a cópia para não estragar o arquivo original
			var jogador_copia = peca_original.duplicate(true)
			jogador_copia.slotsUpgrates.resize(jogador_copia.quantosSlotes)
			pecas_iniciais.append(jogador_copia)
			
			# Adiciona aos desbloqueados
			GameState.adicionar_peca(jogador_copia.id_unico)

	if pecas_iniciais.size() == 0:
		print("ERRO -> Nenhuma peça do Grêmio encontrada no Database!")
	else:
		GameState.jogadores = pecas_iniciais
		#print("✔ Time inicial (Grêmio) carregado com sucesso!")


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
		"bola_leve_02"
	]
	
	for id_carta in ids_cartas_iniciais:
		if Database.cartas_db.has(id_carta):
			GameState.adicionar_carta(id_carta)
		else:
			print("AVISO -> Carta inicial não encontrada no Database: ", id_carta)
			
	#print("✔ Cartas iniciais adicionadas! Total: ", GameState.cartas_desbloqueadas.size())
	
	SaveManager.save_game()

func _on_team_button_pressed() -> void:
	# Instancia a cena nova e adiciona na tela
	var tela = MyTeamScene.instantiate()
	get_parent().add_child(tela)
	self.visible = false

func _on_continue_button_pressed() -> void:
	pass

func _on_new_game_button_pressed() -> void:
	CupManager.newRun()
	if new_game_level_2D != null:
		get_tree().change_scene_to_packed(new_game_level_2D)
	else:
		pass

func _on_settings_button_pressed() -> void:
	pass

func _on_button_pressed() -> void:
	SaveManager.delete_save()


func _on_add_cartas_button_pressed() -> void:
	
	# Garante que o Database já terminou de carregar os arquivos
	if Database.cartas_db.size() == 0:
		print("Erro: O Database de cartas está vazio ou não foi carregado ainda.")
		return
		
	# Varre todos os IDs únicos que existem cadastrados no jogo
	for id_carta in Database.cartas_db.keys():
		GameState.adicionar_carta(id_carta)
	
	
	var pecas_iniciais: Array = []
	
	# ==========================================
	# 1. CARREGAR AS PEÇAS DO GRÊMIO
	# ==========================================
	for id_peca in Database.pecas_db:
		var peca_original = Database.pecas_db[id_peca]
		
		# Procura peças que tenham um Resource de Time equipado e que o nome seja "Grêmio"
		if peca_original is TeamPlayer and peca_original.time and peca_original.time.name == "My Team":
			
			# Faz a cópia para não estragar o arquivo original
			var jogador_copia = peca_original.duplicate(true)
			jogador_copia.slotsUpgrates.resize(jogador_copia.quantosSlotes)
			pecas_iniciais.append(jogador_copia)
			
			# Adiciona aos desbloqueados
			GameState.adicionar_peca(jogador_copia.id_unico)
