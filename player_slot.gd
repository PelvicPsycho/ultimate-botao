extends Control
class_name PlayerSlot

var team_player: TeamPlayer

@onready var icone: TextureRect = $Icone
@onready var nome_label: Label = $Nome
@onready var slots_container: HBoxContainer = $Slots

func setup(tp: TeamPlayer):
	team_player = tp
	icone.texture = tp.foto
	nome_label.text = tp.nome

	if team_player.slotsUpgrates.is_empty():
		team_player.inicializar_slots()

	_criar_botoes()
	_update_visuals()

func _criar_botoes():
	for c in slots_container.get_children():
		c.queue_free()

	for i in range(team_player.quantosSlotes):
		var btn := Button.new()
		btn.text = "Slot " + str(i)
		btn.custom_minimum_size = Vector2(80, 50)
		btn.pressed.connect(_on_slot_click.bind(i))
		slots_container.add_child(btn)

func _on_slot_click(slot_index: int):
	print("CLIQUE NA PEÇA slot:", slot_index)

	var ger = get_tree().current_scene.get_node("GerenciadorCartas")
	ger.aplicar_carta_no_slot(team_player, slot_index)
func _update_visuals():
	for i in range(team_player.quantosSlotes):
		var card = team_player.slotsUpgrates[i]
		var btn: Button = slots_container.get_child(i)

		if card == null:
			btn.text = "Slot " + str(i)
		else:
			btn.text = card.nome
