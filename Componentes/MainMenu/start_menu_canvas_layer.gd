extends CanvasLayer

#@onready var new_game_level: PackedScene = preload("res://MatchScene.tscn")
const TabMenu := preload("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn") 

func _ready():
	SoundMaster.stop_music()
	#print("=== CONFIGURAÇÕES CARREGADAS ===")
	#print("Total de jogadores salvos no GameState: ", GameState.jogadores.size())
#
	if GameState.jogadores.size() == 0:
#		print("Nenhum save encontrado. Carregando time inicial (My Team) do Database...")
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

# Carrega cartas e pecas iniciais se não existe nenhum save
func _carregar_time_inicial():
	var pecas_iniciais: Array = []
	
	# ==========================================
	# 1. CARREGAR AS PEÇAS DO GRÊMIO / MY TEAM
	# ==========================================
	for id_peca in Database.pecas_db:
		var peca_original = Database.pecas_db[id_peca]
		
		# Procura peças que tenham um Resource de Time equipado
		if peca_original is TeamPlayer and peca_original.time and peca_original.time.name == "My Team":
			
			if pecas_iniciais.size() < 5:
				# As primeiras 5 peças vão para o time titular (ativas no campo)
				var jogador_copia = peca_original.duplicate(true)
				jogador_copia.slotsUpgrates.resize(jogador_copia.quantosSlotes)
				pecas_iniciais.append(jogador_copia)
			else:
				# A 6ª peça (e qualquer outra extra) vai direto para o Stack/Banco genérico!
				GameState.adicionar_peca(peca_original.id_unico)

	if pecas_iniciais.size() == 0:
		print("ERRO -> Nenhuma peça do Grêmio encontrada no Database!")
	else:
		GameState.jogadores = pecas_iniciais
		#print("✔ Time inicial carregado com sucesso!")


	# ==========================================
	# 2. CARREGAR CARTAS INICIAIS
	# ==========================================
	var ids_cartas_iniciais: Array[StringName] = [
		"corre_peao_01", 
		"corre_peao_01",
		"defesa_escudo_01",
		"defesa_escudo_01",
		"bola_leve_01",
		"bola_leve_01",
		"gerador_mana_01",
		"encolher_01"
	]
	
	for id_carta in ids_cartas_iniciais:
		if Database.cartas_db.has(id_carta):
			GameState.adicionar_carta(id_carta)
		else:
			print("AVISO -> Carta inicial não encontrada no Database: ", id_carta)
			
	SaveManager.save_game()

func _on_button_pressed() -> void:
	print("Deletou o save")
	SaveManager.delete_save()


func _on_startbutton_pressed() -> void:
	get_tree().change_scene_to_packed(TabMenu)


func _on_add_todas_cartas_pressed() -> void:
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


func _on_addpecasaleatorias_pressed() -> void:
	# Garante que o banco de dados já carregou para não dar erro
	if Database.pecas_db.is_empty():
		print("Erro: O Database de peças está vazio ou ainda não carregou.")
		return
		
	# Pega todos os IDs das peças e transforma em um Array
	var todas_as_chaves = Database.pecas_db.keys()
	
	print("=== Sorteando 5 Peças Aleatórias ===")
	
	# Roda o sorteio 5 vezes
	for i in range(5):
		var id_sorteado = todas_as_chaves.pick_random()
		
		# Adiciona no stack/inventário do GameState
		GameState.adicionar_peca(id_sorteado)
		
		# Pega o nome apenas para imprimir no console e você saber o que ganhou
		var nome_peca = Database.pecas_db[id_sorteado].nome
		print(i + 1, "ª Peça recebida: ", nome_peca)
		
	# Salva o jogo para não perder as peças novas ao fechar
	SaveManager.save_game()
	print("✔ 5 Peças salvas com sucesso no seu inventário!")
