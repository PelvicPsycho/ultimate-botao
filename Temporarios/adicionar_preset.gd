extends Button
class_name PresetButton

## Botão de DEBUG: ignora todos os limites (inventário, slots, PA).
## Apenas força as peças e cartas selecionadas no editor e salva.

# ─── Peças do Preset (uma para cada slot 1-5) ───
@export_group("Peças do Preset", "peca_")
@export var peca_slot_1: TeamPlayer
@export var peca_slot_2: TeamPlayer
@export var peca_slot_3: TeamPlayer
@export var peca_slot_4: TeamPlayer
@export var peca_slot_5: TeamPlayer

# ─── Cartas para cada Peça ───
@export_group("Cartas - Peça 1", "cartas_1_")
@export var cartas_1: Array[CardResource]

@export_group("Cartas - Peça 2", "cartas_2_")
@export var cartas_2: Array[CardResource]

@export_group("Cartas - Peça 3", "cartas_3_")
@export var cartas_3: Array[CardResource]

@export_group("Cartas - Peça 4", "cartas_4_")
@export var cartas_4: Array[CardResource]

@export_group("Cartas - Peça 5", "cartas_5_")
@export var cartas_5: Array[CardResource]


func _ready() -> void:
	pressed.connect(_on_preset_pressed)


func _on_preset_pressed() -> void:
	var pecas: Array[TeamPlayer] = [
		peca_slot_1, peca_slot_2, peca_slot_3, peca_slot_4, peca_slot_5
	]
	var cartas_por_peca: Array[Array] = [
		cartas_1, cartas_2, cartas_3, cartas_4, cartas_5
	]

	# Limpa o time atual
	GameState.jogadores.clear()

	for i in range(5):
		var peca: TeamPlayer = pecas[i]
		if peca == null:
			continue

		# Duplica pra não mexer no original do Database
		var nova = peca.duplicate(true)
		nova.time = CupManager.myTeam

		# Força o array de slots para caber todas as cartas
		var lista_cartas = cartas_por_peca[i]
		var qtd_cartas = 0
		for c in lista_cartas:
			if c != null:
				qtd_cartas += 1

		nova.slotsUpgrates.clear()
		nova.slotsUpgrates.resize(max(nova.quantosSlotes, qtd_cartas))
		nova.quantosSlotes = max(nova.quantosSlotes, qtd_cartas)

		# Equipa as cartas direto, sem checar nada
		var idx = 0
		for carta in lista_cartas:
			if carta != null:
				nova.slotsUpgrates[idx] = carta
				idx += 1

		GameState.jogadores.append(nova)

	# Atualiza CupManager
	var titulares = mini(5, GameState.jogadores.size())
	CupManager.myTeam.mainSquad.clear()
	for j in range(titulares):
		CupManager.myTeam.mainSquad.append(GameState.jogadores[j])

	CupManager.myTeam.collectedSquad.clear()
	for j in range(titulares, GameState.jogadores.size()):
		CupManager.myTeam.collectedSquad.append(GameState.jogadores[j])

	SaveManager.save_game()
	print("PresetButton (DEBUG): Preset aplicado — %d peças equipadas." % GameState.jogadores.size())
