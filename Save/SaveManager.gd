extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> void:
	var data: Dictionary = {
		"players": [],
		"cartas_desbloqueadas": [],
		"pecas_desbloqueadas": []
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

	# Salva os IDs de cartas e peças desbloqueadas (inventário do jogador)
	for carta_id in GameState.cartas_desbloqueadas:
		data["cartas_desbloqueadas"].append(str(carta_id))
	for peca_id in GameState.pecas_desbloqueadas:
		data["pecas_desbloqueadas"].append(str(peca_id))

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

	# ── Restaura cartas e peças desbloqueadas ──
	GameState.cartas_desbloqueadas.clear()
	if parsed.has("cartas_desbloqueadas"):
		for id_str in parsed["cartas_desbloqueadas"]:
			GameState.cartas_desbloqueadas.append(StringName(str(id_str)))

	GameState.pecas_desbloqueadas.clear()
	if parsed.has("pecas_desbloqueadas"):
		for id_str in parsed["pecas_desbloqueadas"]:
			GameState.pecas_desbloqueadas.append(StringName(str(id_str)))

	# Fallback para saves antigos: reconstrói a partir dos jogadores
	if GameState.cartas_desbloqueadas.is_empty() and GameState.pecas_desbloqueadas.is_empty():
		# Será preenchido abaixo enquanto monta a lista de jogadores
		pass

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

	# Fallback: se os arrays de desbloqueio ficaram vazios (save antigo),
	# reconstrói a partir dos jogadores recém-carregados.
	if GameState.cartas_desbloqueadas.is_empty() and GameState.pecas_desbloqueadas.is_empty():
		for peca in lista_final:
			if peca != null:
				if not GameState.pecas_desbloqueadas.has(peca.id_unico):
					GameState.pecas_desbloqueadas.append(peca.id_unico)
				for carta in peca.slotsUpgrates:
					if carta != null and not GameState.cartas_desbloqueadas.has(carta.id_unico):
						GameState.cartas_desbloqueadas.append(carta.id_unico)

	return lista_final

func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove(SAVE_PATH)
			return err == OK
		return false
	return false
