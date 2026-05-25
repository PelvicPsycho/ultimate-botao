extends Control

#var piece_alvo: PhysicsPlayer2D
#var carta1: CardResource
#var carta2: CardResource
#var cartas: Array = []
#
#@onready var botao1: Button = $Botao1
#@onready var botao2: Button = $Botao2
#
#func _ready():
	#mouse_filter = Control.MOUSE_FILTER_STOP
	#visible = false   
#
#func definir_piece(p):
	#piece_alvo = p
	#botao1.add_theme_font_size_override("font_size", 10)
	#botao2.add_theme_font_size_override("font_size", 10)
	#
	#var slots = p.playerInfo.slotsUpgrates 
	## Se a linha acima der erro, volte para: var slots = piece_alvo.slotsUpgrates
#
	## --- TRAVA DO BOTÃO 1 ---
	#if slots.size() > 0 and slots[0] != null:
		#carta1 = slots[0]
		#botao1.text = carta1.nome
		#botao1.disabled = false
		#botao1.visible = true
	#else:
		#carta1 = null
		#botao1.text = "Vazio"
		#botao1.disabled = true
		#botao1.visible = false
#
	## --- TRAVA DO BOTÃO 2 ---
	#if slots.size() > 1 and slots[1] != null:
		#carta2 = slots[1]
		#botao2.text = carta2.nome
		#botao2.disabled = false
		#botao2.visible = true
	#else:
		#carta2 = null
		#botao2.text = "Vazio"
		#botao2.visible = false
#
#func definir_cartas(lista):
	#cartas = lista
#
#func _on_botao_1_pressed():
	#if piece_alvo and carta1:
		#var ms = get_tree().get_root().get_node("MatchScene2d")
		#ms.tentar_usar_carta(piece_alvo, carta1)
	#else:
		#print("Sem carta no slot 1")
	#visible = false
#
#func _on_botao_2_pressed():
	#if piece_alvo and carta2:
		#var ms = get_tree().get_root().get_node("MatchScene2d")
		#ms.tentar_usar_carta(piece_alvo, carta2)
	#else:
		#print("Sem carta no slot 2")
	#visible = false

var piece_alvo: PhysicsPlayer2D
var botoes_gerados: Array = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func definir_piece(p):
	piece_alvo = p

	# Remover botões antigos
	for b in botoes_gerados:
		if is_instance_valid(b):
			b.queue_free()
	botoes_gerados.clear()

	var slots:Array = p.playerInfo.slotsUpgrates
	if slots.is_empty():
		return

	
	var centro = get_rect().size * 0.5
	var raio =100
	var total = slots.size()

	for i in range(total):
		var carta = slots[i]
		if carta == null:
			continue
		var bt := Button.new()
		bt.text = carta.nome
		bt.add_theme_font_size_override("font_size", 15)
		bt.focus_mode = Control.FOCUS_NONE
		bt.clip_text = true
		bt.custom_minimum_size = Vector2(100,56)
		var ang = (TAU * i) / total
		bt.position = centro + Vector2(cos(ang), sin(ang)) * raio
		bt.connect("pressed", Callable(self, "_on_carta_pressionada").bind(carta))
		add_child(bt)
		botoes_gerados.append(bt)


func _on_carta_pressionada(carta: CardResource):
	if not piece_alvo:
		return

	var ms = get_tree().root.get_node("MatchScene2d")
	ms.tentar_usar_carta(piece_alvo, carta)
	visible = false
