extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> void:
	var data: Dictionary = { "players": [] }

	# Agora ele puxa direto do Autoload GameState
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

	return lista_final

func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove(SAVE_PATH)
			return err == OK
		return false
	return false
