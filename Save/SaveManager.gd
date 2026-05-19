extends Node

const SAVE_PATH := "user://savegame.json"

# Salva o array de TeamPlayer no JSON
func save_game(jogadores: Array) -> void:
	var data: Dictionary = { "players": [] }

	for p in jogadores:
		var p_dict: Dictionary = {}
		
		# Salva o caminho da peça
		p_dict["resource_path"] = p.resource_path 
		
		# Cria uma lista apenas com as cartas que realmente estão equipadas
		var cartas_salvas := []
		for carta in p.slotsUpgrates:
			if carta != null:
				cartas_salvas.append(carta.resource_path)

		p_dict["cartas_equipadas"] = cartas_salvas
		data["players"].append(p_dict)

	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("✔ Save criado com sucesso em:", SAVE_PATH)

# Lê o JSON e reconstrói o array de TeamPlayer
func load_game() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("players"):
		return []

	var lista_final: Array = []
	
	for entrada in parsed["players"]:
		var path = entrada.get("resource_path", "")
		
		if path != "" and ResourceLoader.exists(path):
			# 1. Carrega a peça original com valores iniciais
			var tp = load(path).duplicate(true) 
			
			# 2. Prepara o array de slots com a capacidade base do arquivo .tres
			tp.slotsUpgrates.clear()
			tp.slotsUpgrates.resize(tp.quantosSlotes)

			# 3. Puxa a lista de cartas do JSON e vai colocando nos primeiros espaços livres
			var cartas_salvas: Array = entrada.get("cartas_equipadas", [])
			var index_slot = 0
			
			for card_path in cartas_salvas:
				if card_path != null and ResourceLoader.exists(card_path):
					# Trava de segurança: só equipa se ainda houver espaço físico na peça
					if index_slot < tp.quantosSlotes:
						tp.slotsUpgrates[index_slot] = load(card_path)
						index_slot += 1

			lista_final.append(tp)

	return lista_final

# Deleta o arquivo de save do disco
func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove_absolute(SAVE_PATH)
			return err == OK
		return false
	return false
