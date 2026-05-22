extends Node

var inventario_cartas: Array[CardResource] = []
var meu_time_titular: Team

func _ready() -> void:
	# Chama a função passando o caminho exato da sua pasta de cartas
	_carregar_todas_as_cartas_da_pasta("res://Componentes/Cartas/CardResorce/")
	
	_criar_time_de_teste()

func _carregar_todas_as_cartas_da_pasta(caminho_da_pasta: String):
	# Garante que o caminho termina com uma barra
	if not caminho_da_pasta.ends_with("/"):
		caminho_da_pasta += "/"
		
	# Abre a pasta e pega o nome de todos os arquivos lá dentro
	var arquivos = DirAccess.get_files_at(caminho_da_pasta)
	
	for arquivo in arquivos:
		# Só tenta carregar se o arquivo for um Resource (.tres)
		# (Isso evita tentar carregar arquivos .gd ou imagens soltas)
		if arquivo.ends_with(".tres") or arquivo.ends_with(".res"):
			
			var caminho_completo = caminho_da_pasta + arquivo
			var recurso_carregado = load(caminho_completo)
			
			# Checagem de segurança: Garante que o arquivo lido é realmente uma carta
			if recurso_carregado is CardResource:
				inventario_cartas.append(recurso_carregado)
				
	print("Sucesso! ", inventario_cartas.size(), " cartas foram carregadas da pasta.")

func _criar_time_de_teste():
	meu_time_titular = Team.new()
	meu_time_titular.name = "Botões F.C."
	
	for i in range(1, 6):
		var player = TeamPlayer.new()
		player.nome = "Botão #" + str(i)
		player.quantosSlotes = 4
		player.força = 50 + (i * 5)
		player.PA = 3
		player.inicializar_slots()
		
		meu_time_titular.mainSquad.append(player)

func imprimir_status_do_time() -> void:
	if not meu_time_titular:
		print("❌ Erro: Nenhum time titular foi inicializado para impressão.")
		return

	print("\n==================================================")
	print("📊 DIAGNÓSTICO DO ELENCO: ", meu_time_titular.name.to_upper())
	print("==================================================")
	
	for i in range(meu_time_titular.mainSquad.size()):
		var player = meu_time_titular.mainSquad[i]
		
		print("\n📍 Posição/Slot %d: %s (Camisa #%d)" % [i + 1, player.nome, player.num_camisa])
		print("   ↳ Atributos -> Força: %d | PA: %d | Rank: %s" % [player.força, player.PA, TeamPlayer.Rank.keys()[player.rank]])
		print("   ↳ Gerenciamento de Slots (%d totais):" % player.quantosSlotes)
		
		if player.slotsUpgrates.size() == 0:
			print("     [!] Alerta: Os slots desta peça não foram inicializados.")
			continue
			
		for s in range(player.slotsUpgrates.size()):
			var carta = player.slotsUpgrates[s]
			if carta != null:
				print("     [%d] 🃏 %s | Efeito: \"%s\" (Custo: %d slots)" % [s + 1, carta.nome, carta.descricao, carta.custoSlotes])
			else:
				print("     [%d] 🔲 [Espaço Vazio]" % [s + 1])
				
	print("\n==================================================")
