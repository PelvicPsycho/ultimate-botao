extends Control

@export_group("Configurações do Banner")
@export var velocidade: float = 150.0
@export var texto_do_banner: String = "TORNEIO"

@export var bloco1: HBoxContainer
@export var bloco2: HBoxContainer
@export var bloco3: HBoxContainer
@export var esconder_label: bool = false

var largura_bloco: float = 0.0

func _ready() -> void:
	if esconder_label:
		var todos_os_control = find_children("Control", "Control")
		for child in todos_os_control:
			child.visible = false
	_aplicar_texto_nos_blocos(texto_do_banner)
	await get_tree().process_frame
	
	largura_bloco = bloco1.size.x
	
	# Posiciona todo mundo em fila indiana
	bloco1.position = Vector2(0, 0)
	bloco2.position = Vector2(largura_bloco, 0)
	bloco3.position = Vector2(largura_bloco * 2.0, 0) # Fica nas costas do bloco 2


func _aplicar_texto_nos_blocos(novo_texto: String) -> void:
	var todos_os_labels = find_children("*", "Label")
	for label in todos_os_labels:
		label.text = novo_texto
		if esconder_label:
			label.visible = false


func _process(delta: float) -> void:
	# Move os três fisicamente para a esquerda
	bloco1.position.x -= velocidade * delta
	bloco2.position.x -= velocidade * delta
	bloco3.position.x -= velocidade * delta
	
	# Agora multiplicamos a largura por 3.0 para teletransportar para o fim da fila longa
	if velocidade > 0:
		if bloco1.position.x <= -largura_bloco:
			bloco1.position.x += largura_bloco * 3.0
			
		if bloco2.position.x <= -largura_bloco:
			bloco2.position.x += largura_bloco * 3.0
			
		if bloco3.position.x <= -largura_bloco:
			bloco3.position.x += largura_bloco * 3.0
	else:
		if bloco1.position.x >= +largura_bloco:
			bloco1.position.x -= largura_bloco * 3.0
			
		if bloco2.position.x >= +largura_bloco:
			bloco2.position.x -= largura_bloco * 3.0
			
		if bloco3.position.x >= +largura_bloco:
			bloco3.position.x -= largura_bloco * 3.0
