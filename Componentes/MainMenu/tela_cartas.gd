extends Control

func _ready():
	# conectar slots
	await get_tree().process_frame
	for peca in $ContainerDePecas.get_children():
		peca.slot_clicado.connect(_on_slot_clicado)


func _on_slot_clicado(slot_index, team_player):
	var ger = $GerenciadorCartas
	var carta = ger.carta_selecionada

	if carta == null:
		print("Nenhuma carta selecionada.")
		return

	team_player.slotsUpgrates.resize(team_player.quantosSlotes)
	team_player.slotsUpgrates[slot_index] = carta
	team_player.aplicar_buff(carta)

	ger.carta_selecionada = null




func _on_button_pressed() -> void:
	SaveManager.save_game()

	# volta ao menu
	var menu = get_parent().get_node("MainMenu")
	menu.visible = true

	queue_free()

	pass # Replace with function body.
