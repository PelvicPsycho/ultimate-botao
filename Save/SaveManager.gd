extends Node

const SAVE_PATH := "user://savegame.json"


func save_game(jogadores: Array) -> void:
	var data: Dictionary = {
		"players": []
	}

	for p in jogadores:
		var p_dict: Dictionary = {}
		p_dict["nome"] = p.nome
		p_dict["foto"] = p.foto.resource_path

		var slots := []
		slots.resize(p.slotsUpgrates.size())

		for i in p.slotsUpgrates.size():
			var card = p.slotsUpgrates[i]
			if card:
				slots[i] = card.resource_path
			else:
				slots[i] = null

		p_dict["slots"] = slots

		data["players"].append(p_dict)

	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

	print("✔ Save criado em:", SAVE_PATH)



func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("⚠ Nenhum save encontrado")
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed :Dictionary= JSON.parse_string(text)

	if parsed == null:
		print("❌ JSON inválido")
		return {}

	return parsed
func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove_absolute(SAVE_PATH)
			return err == OK
		return false
	return false
