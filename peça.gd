extends Control
class_name Peça

signal slot_clicado(slot_index: int, team_player: TeamPlayer)

@export var team_player: TeamPlayer

@onready var foto: TextureRect = $Foto
@onready var nome_label: Label = $Nome
@onready var slots: HBoxContainer = $Slots

func _ready():
	_atualizar_info()
	_criar_botoes_dos_slots()

func _atualizar_info():
	foto.texture = team_player.foto
	nome_label.text = team_player.nome

func _criar_botoes_dos_slots():
	for c in slots.get_children():
		c.queue_free()

	for i in range(team_player.quantosSlotes):
		var btn := Button.new()
		btn.text = "Slot " + str(i)
		btn.pressed.connect(_on_slot_press.bind(i))
		slots.add_child(btn)

func _on_slot_press(slot_index: int):
	print("PEÇA RECEBEU O CLIQUE NO SLOT:", slot_index)
	slot_clicado.emit(slot_index, team_player)

	
func update_visuals():
	for i in range(team_player.quantosSlotes):
		var card = team_player.slotsUpgrates[i]
		var btn: Button = slots.get_child(i)

		if card:
			btn.text = card.nome
		else:
			btn.text = "Slot " + str(i)
func _buscar_gerenciador_cartas():
	var root = get_tree().current_scene
	return root.find_child("GerenciadorCartas", true, false)
func _get_gerenciador():
	var parent = get_parent()
	if parent == null:
		return null

	if parent.has_node("GerenciadorCartas"):
		return parent.get_node("GerenciadorCartas")

	print("⚠ GerenciadorCartas não está no mesmo nível da Peça!")
	return null
