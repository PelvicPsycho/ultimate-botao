extends Node

const SAVE_PATH := "user://savegame.json"

# Salva o array de TeamPlayer no JSON
func save_game(jogadores: Array) -> void:
	var data: Dictionary = { "players": [] }

	for p in jogadores:
		var p_dict: Dictionary = {}
		
		# Salva o caminho do arquivo .tres original da peça para não perder os status base
		p_dict["resource_path"] = p.resource_path 
		
		var slots := []
		slots.resize(p.slotsUpgrates.size())

		for i in p.slotsUpgrates.size():
			var card = p.slotsUpgrates[i]
			slots[i] = card.resource_path if card else null

		p_dict["slots"] = slots
		data["players"].append(p_dict)

	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

	print("✔ Save criado com sucesso em:", SAVE_PATH)

# Lê o JSON e reconstrói o array de TeamPlayer
func load_game() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		print("⚠ Nenhum save encontrado")
		return []

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("players"):
		print("❌ JSON inválido")
		return []

	var lista_final: Array = []
	
	for entrada in parsed["players"]:
		var path = entrada.get("resource_path", "")
		
		if path != "" and ResourceLoader.exists(path):
			# Usa duplicate(true) para não alterar o arquivo original no HD enquanto joga
			var tp = load(path).duplicate(true) 
			
			var slots_json: Array = entrada.get("slots", [])
			tp.quantosSlotes = slots_json.size()
			tp.slotsUpgrates.resize(tp.quantosSlotes)

			for i in tp.quantosSlotes:
				var card_path = slots_json[i]
				if card_path != null and ResourceLoader.exists(card_path):
					var carta = load(card_path)
					tp.slotsUpgrates[i] = carta
					# A aplicação definitiva de buffs foi removida daqui, 
					# pois a interface agora calcula tudo dinamicamente!
				else:
					tp.slotsUpgrates[i] = null

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
