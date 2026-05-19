extends Node

var jogadores: Array = []
var inventario_cartas: Array[CardResource] = []

func _ready():
	# Usa o SaveManager atualizado para puxar o save logo que o jogo abre
	jogadores = SaveManager.load_game()
	
	# Carrega as cartas
	_carregar_todas_as_cartas_da_pasta("res://Componentes/Cartas/CardResorce/")

# --- FUNÇÃO: CARREGAR CARTAS DO DIRETÓRIO ---
func _carregar_todas_as_cartas_da_pasta(caminho_da_pasta: String):
	if not caminho_da_pasta.ends_with("/"):
		caminho_da_pasta += "/"
		
	var arquivos = DirAccess.get_files_at(caminho_da_pasta)
	
	for arquivo in arquivos:
		if arquivo.ends_with(".tres") or arquivo.ends_with(".res"):
			var recurso_carregado = load(caminho_da_pasta + arquivo)
			if recurso_carregado is CardResource:
				inventario_cartas.append(recurso_carregado)

# --- FUNÇÃO: DIAGNÓSTICO DO TIME ---
func imprimir_status_do_time() -> void:
	print("\n==================================================")
	print("📊 DIAGNÓSTICO DO ELENCO ATUAL")
	print("==================================================")
	
	for i in range(jogadores.size()):
		var player = jogadores[i]
		
		# --- CHECAGEM DE SEGURANÇA DOS STATUS BASE ---
		var f_atual = player.força if "força" in player else 50
		var pa_atual = player.PA if "PA" in player else 3
		
		print("\n📍 Slot %d: %s" % [i + 1, player.nome])
		print("   ↳ Força: %d | PA: %d" % [f_atual, pa_atual])
		
		for s in range(player.slotsUpgrates.size()):
			var carta = player.slotsUpgrates[s]
			if carta != null:
				print("     [%d] 🃏 %s" % [s + 1, carta.nome])
			else:
				print("     [%d] 🔲 [Vazio]" % [s + 1])
	print("==================================================\n")
