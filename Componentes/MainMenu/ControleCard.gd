extends Control

@onready var grid := $"."
var carta_visual_scene := preload("res://Componentes/Cartas/CartaVisual.tscn")
var carta_selecionada: CardResource 
var nó_carta_visual: Node = null
var peca_futebol_alvo: Player 
func _ready():
	var lista_cartas := carregar_cartas()
	for carta_resource in lista_cartas:
		var carta_ui = carta_visual_scene.instantiate()
		
		carta_ui.configurar(carta_resource)
		grid.add_child(carta_ui)
		
		# USANDO BIND: Envia o card_resource (do sinal) + a própria carta_ui
		carta_ui.carta_clicada.connect(selecionar_carta.bind(carta_ui))
func selecionar_carta(card_res: CardResource,instancia_visual: Node):
	carta_selecionada = card_res
	nó_carta_visual = instancia_visual
	print("Carta selecionada: ", carta_selecionada.nome)
	# Opcional: Mudar o cursor para indicar que tem uma carta "na mão"

# Esta função será chamada quando uma peça for clicada
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
