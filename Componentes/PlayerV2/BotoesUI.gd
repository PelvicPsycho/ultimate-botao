extends Control

var piece_alvo: Player
var carta1
var carta2
var cartas: Array = []
@onready var botao1: Button = $Botao1
@onready var botao2: Button = $Botao2
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false   
func definir_piece(p):
	piece_alvo = p
	botao1.add_theme_font_size_override("font_size", 10)
	botao2.add_theme_font_size_override("font_size", 10)
	# Leia as cartas DIRETAMENTE do playerInfo
	var slots :Array = p.playerInfo.slotsUpgrates

	if slots.size() > 0:
		carta1 = slots[0]
		botao1.text = carta1.nome
	else:
		carta1 = null
		botao1.text = "Sem Carta"
	if slots.size() > 1:
		carta2 = slots[1]
		botao2.text = carta2.nome 
	else:
		carta2 = null
		botao2.text = "Sem Carta"
func definir_cartas(lista):
	cartas = lista
func _on_botao_1_pressed():
	if piece_alvo and carta1:
		var ms = get_tree().get_root().get_node("MatchScene")
		ms.tentar_usar_carta(piece_alvo, carta1)
		
	else:
		print("Sem carta no slot 1")
	visible = false
func _on_botao_2_pressed():
	if piece_alvo and carta2:
		var ms = get_tree().get_root().get_node("MatchScene")
		ms.tentar_usar_carta(piece_alvo, carta2)
	else:
		print("Sem carta no slot 2")
	visible = false
	
