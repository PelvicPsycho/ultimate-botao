extends Control

var piece_alvo: Player
var carta1: CardResource
var carta2: CardResource
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
	
	var slots = p.playerInfo.slotsUpgrates 
	# Se a linha acima der erro, volte para: var slots = piece_alvo.slotsUpgrates

	# --- TRAVA DO BOTÃO 1 ---
	if slots.size() > 0 and slots[0] != null:
		carta1 = slots[0]
		botao1.text = carta1.nome
		botao1.disabled = false
		botao1.visible = true
	else:
		carta1 = null
		botao1.text = "Vazio"
		botao1.disabled = true
		botao1.visible = false

	# --- TRAVA DO BOTÃO 2 ---
	if slots.size() > 1 and slots[1] != null:
		carta2 = slots[1]
		botao2.text = carta2.nome
		botao2.disabled = false
		botao2.visible = true
	else:
		carta2 = null
		botao2.text = "Vazio"
		botao2.visible = false

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
