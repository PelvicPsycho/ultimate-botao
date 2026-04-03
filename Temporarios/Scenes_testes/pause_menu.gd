extends CanvasLayer

var Pecas_Jogo: Array[Player] = []

func _ready():
	# Garante que o menu comece invisível quando o jogo roda
	hide()
	# Caminho para o VBoxContainer que guarda todos os HBoxContainers do debug
	var vbox_debug = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug"
	
	# Passa por todos os filhos do VboxDebug
	for child in vbox_debug.get_children():
		# Verifica se o filho é um HBoxContainer (ignorando os Labels de título como "Pecas" e "Bola")
		if child is HBoxContainer:
			var slider: HSlider = null
			var label_valor: Label = null
			
			# Procura o Slider e o Label de valor dentro desse HBoxContainer
			for item in child.get_children():
				if item is HSlider:
					slider = item
				elif item is Label and item.name == "ValorSlider":
					label_valor = item
					
			# Se encontrou tanto o Slider quanto o Label na mesma linha, faz a mágica:
			if slider and label_valor:
				# 1. Define o valor inicial no momento em que o jogo abre
				label_valor.text = str(slider.value)
				
				# 2. Conecta o sinal dinamicamente usando uma função anônima (lambda).
				# Assim, ao arrastar o slider, o texto atualiza sozinho!
				slider.value_changed.connect(func(novo_valor): label_valor.text = str(novo_valor))
	await get_tree().process_frame
	pegar_todas_pecas()


func _unhandled_input(event):
	# "ui_cancel" é a tecla ESC por padrão
	if event.is_action_pressed("ui_cancel"):
		alternar_pause()

func alternar_pause():
	var novo_estado = not get_tree().paused
	get_tree().paused = novo_estado
	visible = novo_estado
	
	# IMPORTANTE: Se o seu jogo for de tiro (FPS) ou capturar o mouse,
	# descomente as linhas abaixo para liberar o cursor no menu:
#	if novo_estado:
#		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#	else:
#		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_color_rect__fundo_preto_gui_input(event: InputEvent) -> void:
	# 1. Verifica se foi um clique de mouse (Botão Esquerdo pressionado)
	var clicou_com_mouse = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	
	# 2. Verifica se foi um toque na tela do celular (Dedo encostou na tela)
	var tocou_com_dedo = event is InputEventScreenTouch and event.pressed
	
	# Se qualquer um dos dois acontecer, fecha o menu
	if clicou_com_mouse or tocou_com_dedo:
		alternar_pause()

func _on_button__continuar_pressed() -> void:
	alternar_pause()

func _on_button__recomecar_pressed() -> void:
	alternar_pause() # Despausa antes de recarregar para evitar bugs
	get_tree().reload_current_scene()

func _on_button__menu_inicial_pressed() -> void:
	print ("Falta o menu inicial")
	alternar_pause()
	# Substitua pelo caminho da sua cena de menu principal
#	get_tree().change_scene_to_file("res://cenas/menu_principal.tscn")

func pegar_todas_pecas():
	Pecas_Jogo.clear()
	var nodes_pecas = get_tree().get_nodes_in_group("Players")
	for node in nodes_pecas:
		if node is Player:
			Pecas_Jogo.append(node as Player)

func _on_forca_multiplicador_value_changed(value: float) -> void:
	var labelValor = %ForcaMultiplicador.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.forca_multiplicador = value

func _on_forca_maxima_value_changed(value: float) -> void:
	var labelValor = %ForcaMaxima.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.forca_maxima = value

func _on_distancia_raio_value_changed(value: float) -> void:
	var labelValor = %DistanciaRaio.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.raio_saida_pixels = value

func _on_friccao_value_changed(value: float) -> void:
	var labelValor = %Friccao.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.physics_material_override.friction = value

func _on_bounce_value_changed(value: float) -> void:
	var labelValor = %Bounce.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.physics_material_override.bounce = value

func _on_rough_value_changed(value: float) -> void:
	var labelValor = %Rough.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.physics_material_override.rough = value
