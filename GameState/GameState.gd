extends Node

const SAVE_PATH := "user://savegame.json"

var jogadores: Array = []


func _ready():
	jogadores = load_game()



##############################################
# SALVAR JOGADORES → JSON EM user://
##############################################
func save_game(jogadores_lista: Array) -> void:
	var data: Dictionary = {
		"players": []
	}

	for p in jogadores_lista:
		var p_dict: Dictionary = {}
		p_dict["nome"] = p.nome

		# caminho da foto
		p_dict["foto"] = p.foto.resource_path if p.foto else null

		# slots
		var slots := []
		slots.resize(p.slotsUpgrates.size())

		for i in p.slotsUpgrates.size():
			var card_resource = p.slotsUpgrates[i]
			slots[i] = card_resource.resource_path if card_resource else null

		p_dict["slots"] = slots
		data["players"].append(p_dict)

	var text := JSON.stringify(data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

	print("✔ Save criado em:", SAVE_PATH)



##############################################
# CARREGAR JSON → RETORNAR DICTIONARY
##############################################
func load_json_raw() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("⚠ Nenhum save encontrado em user://")
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed :Dictionary= JSON.parse_string(text)

	if typeof(parsed) != TYPE_DICTIONARY:
		print("❌ JSON inválido")
		return {}

	return parsed



##############################################
# CONVERTER JSON → TeamPlayer
##############################################
func converter_para_teamplayers(parsed: Dictionary) -> Array[TeamPlayer]:
	var lista_final: Array[TeamPlayer] = []

	if not parsed.has("players"):
		return lista_final

	for entrada in parsed["players"]:
		var tp := TeamPlayer.new()

		tp.nome = entrada.get("nome", "Sem Nome")

		# carregar foto
		if entrada.has("foto") and entrada["foto"] != null:
			tp.foto = load(entrada["foto"])

		# carregar slots
		var slots_json: Array = entrada.get("slots", [])
		tp.quantosSlotes = slots_json.size()
		tp.slotsUpgrates.resize(tp.quantosSlotes)

		for i in tp.quantosSlotes:
			var path = slots_json[i]
			if path != null:
				tp.slotsUpgrates[i] = load(path)
			else:
				tp.slotsUpgrates[i] = null

		lista_final.append(tp)

	return lista_final



##############################################
# CARREGAR SAVEGAME → RETORNAR TeamPlayers
##############################################
func load_game() -> Array[TeamPlayer]:
	var raw := load_json_raw()

	if raw.size() == 0:
		return []

	return converter_para_teamplayers(raw)



##############################################
# DELETAR SAVE
##############################################
func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			var err := dir.remove_absolute(SAVE_PATH)
			return err == OK

	return false
