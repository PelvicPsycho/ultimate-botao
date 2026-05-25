extends Node

var jogadores: Array = []

# Guardam apenas os nomes (IDs) do que o jogador conquistou
var cartas_desbloqueadas: Array[StringName] = []
var pecas_desbloqueadas: Array[StringName] = []

func _ready():
	_restaurar_estado_completo_do_save()

## Restaura jogadores, cartas e peças desbloqueadas a partir do arquivo de save.
func _restaurar_estado_completo_do_save() -> void:
	const SAVE_PATH := "user://savegame.json"

	jogadores = SaveManager.load_game()

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	# Restaura cartas desbloqueadas
	cartas_desbloqueadas.clear()
	if parsed.has("cartas_desbloqueadas"):
		for id_str in parsed["cartas_desbloqueadas"]:
			cartas_desbloqueadas.append(StringName(str(id_str)))

	# Restaura peças desbloqueadas
	pecas_desbloqueadas.clear()
	if parsed.has("pecas_desbloqueadas"):
		for id_str in parsed["pecas_desbloqueadas"]:
			pecas_desbloqueadas.append(StringName(str(id_str)))

	# Fallback para saves antigos (sem os arrays de desbloqueio):
	# reconstrói a partir dos jogadores carregados.
	if cartas_desbloqueadas.is_empty() and pecas_desbloqueadas.is_empty():
		for peca in jogadores:
			if peca != null:
				if not pecas_desbloqueadas.has(peca.id_unico):
					pecas_desbloqueadas.append(peca.id_unico)
				for carta in peca.slotsUpgrates:
					if carta != null and not cartas_desbloqueadas.has(carta.id_unico):
						cartas_desbloqueadas.append(carta.id_unico)

func imprimir_status_do_time() -> void:
	print("\n==================================================")
	print("📊 DIAGNÓSTICO DO ELENCO ATUAL")
	print("==================================================")
	for i in range(jogadores.size()):
		var player = jogadores[i]
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

#Funcao para soltar as cartas de uma peca numa fusao ou aposta e as cartas nao bugarem
func preparar_peca_para_fusao(peca: TeamPlayer): 
	for i in range(peca.slotsUpgrates.size()):
		if peca.slotsUpgrates[i] != null:
			print("Carta devolvida ao inventário: ", peca.slotsUpgrates[i].nome)
			peca.slotsUpgrates[i] = null
