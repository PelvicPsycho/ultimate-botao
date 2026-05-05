extends Control

@onready var grid := $"."
var carta_visual_scene := preload("res://Componentes/Cartas/CartaVisual.tscn")
var carta_selecionada: CardResource 
func _ready():
	var lista_cartas := carregar_cartas()
	for carta_resource in lista_cartas:
		var carta_ui = carta_visual_scene.instantiate()
		carta_ui.configurar(carta_resource)
		grid.add_child(carta_ui)
		carta_ui.carta_clicada.connect(selecionar_carta)
func selecionar_carta(resource: CardResource):
	carta_selecionada = resource
	print("Carta selecionada para usar: ", resource.nome)
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
