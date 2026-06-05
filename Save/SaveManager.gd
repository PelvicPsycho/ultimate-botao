extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> void:
	var data: Dictionary = {
		"players": [],
		"cartas_desbloqueadas": {},
		"pecas_desbloqueadas": {},
		"ultimo_torneio_jogado": GameState.ultimo_torneio_jogado,
		"torneios_desbloqueados": GameState.torneios_desbloqueados,
		"config_audio": {
			"master": SoundMaster.volume_master,
			"bgm": SoundMaster.volume_BGM,
			"sfx": SoundMaster.volume_SFX,
			"mutado": AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
			}
	}

	# Salva os jogadores (peças) e suas cartas equipadas
	for p in GameState.jogadores:
		var p_dict: Dictionary = {}
		
		# Salva o ID ÚNICO da peça, e não o caminho
		p_dict["id_peca"] = p.id_unico 
		
		var cartas_salvas := []
		for carta in p.slotsUpgrates:
			if carta != null:
				# Salva o ID ÚNICO da carta
				cartas_salvas.append(carta.id_unico)

		p_dict["cartas_equipadas"] = cartas_salvas
		data["players"].append(p_dict)

	# Salva os stacks: { "id_carta": quantidade, ... }
	for carta_id in GameState.cartas_desbloqueadas:
		data["cartas_desbloqueadas"][str(carta_id)] = GameState.cartas_desbloqueadas[carta_id]
	for peca_id in GameState.pecas_desbloqueadas:
		data["pecas_desbloqueadas"][str(peca_id)] = GameState.pecas_desbloqueadas[peca_id]

	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("✔ Save criado com sucesso em:", SAVE_PATH)


func load_game() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("players"):
		return []
	
	if parsed.has("config_audio"):
		var configs = parsed["config_audio"]
		
		# Restaura os valores nas variáveis do SoundMaster (usando os padrões 100/50 caso o save seja antigo e não tenha a chave)
		SoundMaster.volume_master = configs.get("master", 100.0)
		SoundMaster.volume_BGM = configs.get("bgm", 50.0)
		SoundMaster.volume_SFX = configs.get("sfx", 100.0)
		
		# Aplica os volumes físicos no AudioServer (convertendo de 0-100 para 0.0-1.0 linear)
		var master_bus = AudioServer.get_bus_index("Master")
		var bgm_bus = AudioServer.get_bus_index("BGM")
		
		AudioServer.set_bus_volume_linear(master_bus, SoundMaster.volume_master / 100.0)
		AudioServer.set_bus_volume_linear(bgm_bus, SoundMaster.volume_BGM / 100.0)
		SoundMaster.set_sfx_volume(SoundMaster.volume_SFX / 100.0)
		
		# Restaura o estado do checkbox de Mute
		var esta_mutado = configs.get("mutado", false)
		AudioServer.set_bus_mute(master_bus, esta_mutado)
	
	GameState.ultimo_torneio_jogado = parsed.get("ultimo_torneio_jogado", "")
	
	# ── Restaura torneios desbloqueados ──
	GameState.torneios_desbloqueados.clear()
	if parsed.has("torneios_desbloqueados"):
		var torneios_data = parsed["torneios_desbloqueados"]
		if typeof(torneios_data) == TYPE_ARRAY:
			for nome_cup in torneios_data:
				GameState.torneios_desbloqueados.append(str(nome_cup))
	
	# ── Restaura cartas desbloqueadas (formato novo: dict, antigo: array) ──
	GameState.cartas_desbloqueadas.clear()
	if parsed.has("cartas_desbloqueadas"):
		var cartas_data = parsed["cartas_desbloqueadas"]
		if typeof(cartas_data) == TYPE_DICTIONARY:
			# Novo formato: {"id": 3, "id2": 1}
			for id_str in cartas_data:
				GameState.cartas_desbloqueadas[StringName(str(id_str))] = int(cartas_data[id_str])
		elif typeof(cartas_data) == TYPE_ARRAY:
			# Formato antigo: ["id1", "id1", "id2"] → converte pra dict
			for id_str in cartas_data:
				var key = StringName(str(id_str))
				GameState.cartas_desbloqueadas[key] = GameState.cartas_desbloqueadas.get(key, 0) + 1

	# ── Restaura peças desbloqueadas (mesma lógica) ──
	GameState.pecas_desbloqueadas.clear()
	if parsed.has("pecas_desbloqueadas"):
		var pecas_data = parsed["pecas_desbloqueadas"]
		if typeof(pecas_data) == TYPE_DICTIONARY:
			for id_str in pecas_data:
				GameState.pecas_desbloqueadas[StringName(str(id_str))] = int(pecas_data[id_str])
		elif typeof(pecas_data) == TYPE_ARRAY:
			for id_str in pecas_data:
				var key = StringName(str(id_str))
				GameState.pecas_desbloqueadas[key] = GameState.pecas_desbloqueadas.get(key, 0) + 1

	# Fallback para saves antigos sem nenhum dos arrays
	if GameState.cartas_desbloqueadas.is_empty() and GameState.pecas_desbloqueadas.is_empty():
		pass  # será preenchido no fallback abaixo

	# ── Restaura jogadores ──
	var lista_final: Array = []
	
	for entrada in parsed["players"]:
		var id_peca = entrada.get("id_peca", "")
		
		# Busca a peça no Database usando o ID
		var peca_original = Database.pecas_db.get(id_peca)
		if peca_original:
			var tp = peca_original.duplicate(true) 
			tp.slotsUpgrates.clear()
			tp.slotsUpgrates.resize(tp.quantosSlotes)

			var cartas_salvas: Array = entrada.get("cartas_equipadas", [])
			var index_slot = 0
			
			for card_id in cartas_salvas:
				# Busca a carta no Database usando o ID
				var carta_real = Database.get_carta(card_id)
				if carta_real != null and index_slot < tp.quantosSlotes:
					tp.slotsUpgrates[index_slot] = carta_real
					index_slot += 1

			lista_final.append(tp)

	# Fallback: se os dicionários ficaram vazios (save antigo sem arrays),
	# reconstrói a partir dos jogadores recém-carregados.
	if GameState.cartas_desbloqueadas.is_empty() and GameState.pecas_desbloqueadas.is_empty():
		for peca in lista_final:
			if peca != null:
				var pid = peca.id_unico
				GameState.pecas_desbloqueadas[pid] = GameState.pecas_desbloqueadas.get(pid, 0) + 1
				for carta in peca.slotsUpgrates:
					if carta != null:
						var cid = carta.id_unico
						GameState.cartas_desbloqueadas[cid] = GameState.cartas_desbloqueadas.get(cid, 0) + 1

	return lista_final

func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove(SAVE_PATH)
			return err == OK
		return false
	return false
