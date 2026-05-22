extends Control
class_name GerenciadorCartas

var carta_selecionada: CardResource = null
@onready var grid = $"."

var carta_visual_scene := preload("res://Componentes/Cartas/CartaVisual.tscn")

func _ready():
	var lista = carregar_cartas()

	for carta_resource in lista:
		var carta_ui = carta_visual_scene.instantiate()
		carta_ui.configurar(carta_resource)
		carta_ui.carta_clicada.connect(_on_carta_selecionada)
		grid.add_child(carta_ui)

func _on_carta_selecionada(card: CardResource):
	carta_selecionada = card
	print("Carta selecionada:", card.nome)
	print("GERENCIADOR RECEBEU A CARTA:", card.nome)

func carregar_cartas() -> Array:
	var lista: Array = []
	var dir := DirAccess.open("res://Componentes/Cartas/CardResorce/")

	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()

		while file != "":
			if file.ends_with(".tres"):
				var resource = load("res://Componentes/Cartas/CardResorce/" + file)
				lista.append(resource)
			file = dir.get_next()

	return lista
	
func _on_slot_clicado(slot_index: int, team_player: TeamPlayer):
	print("GERENCIADOR RECEBEU O CLIQUE DO SLOT:", slot_index)
	print("CARTA SELECIONADA:", carta_selecionada)

	if carta_selecionada:
		team_player.slotsUpgrates[slot_index] = carta_selecionada
		team_player.aplicar_buff(carta_selecionada)
		carta_selecionada = null
	else:
		print("Nenhuma carta selecionada.")

func receber_carta_do_click(card: CardResource):
	carta_selecionada = card
	print("CARTA SELECIONADA:", card.nome)
