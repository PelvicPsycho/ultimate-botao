extends CanvasLayer

var Pecas_Jogo: Array[Player] = []
var a_bola: Ball

@onready var recursos: Array[Padrao] = [
	preload("res://Recursos/Padroes/PadraoVS.tres"),
	preload("res://Recursos/Padroes/Padrao.tres"),
	preload("res://Recursos/Padroes/PadraoIgor.tres"),
	]

@onready var padrao_atual: Padrao = recursos[0] 

@onready var padrao_atual_index = 0

@onready var label_padrao = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/PadroesPerfis/Label_Padrao"

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
	pegar_a_bola()
	carregar_recursos()
	
	label_padrao.text = padrao_atual.name
	set_padrao_atual()


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
		pegar_a_bola()

func _on_button__continuar_pressed() -> void:
	alternar_pause()

func _on_button__recomecar_pressed() -> void:
	alternar_pause() # Despausa antes de recarregar para evitar bugs
	get_tree().reload_current_scene()

func _on_button__menu_inicial_pressed() -> void:
	get_tree().change_scene_to_file("res://Componentes/MainMenu/main_menu.tscn")

func pegar_todas_pecas():
	Pecas_Jogo.clear()
	var nodes_pecas = get_tree().get_nodes_in_group("Players")
	for node in nodes_pecas:
		if node is Player:
			Pecas_Jogo.append(node as Player)

func pegar_a_bola():
	a_bola = get_tree().get_first_node_in_group("Balls")

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

func _on_linear_damp_value_changed(value: float) -> void:
	var labelValor = %LinearDamp.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.linear_damp = value

func _on_peso_bola_value_changed(value: float) -> void:
	var labelValor = %PesoBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.mass = value

func _on_bounce_bola_value_changed(value: float) -> void:
	var labelValor = %BounceBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.physics_material_override.bounce = value

func _on_linear_damp_bola_value_changed(value: float) -> void:
	var labelValor = %LinearDampBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.linear_damp = value

func _on_friccao_bola_value_changed(value: float) -> void:
	var labelValor = %FriccaoBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.physics_material_override.friction = value

func _on_shakedown_amp_min_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer10/ShakedownAmpMin"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.shake_amplitude_min = value


func _on_shakedown_amp_max_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer11/ShakedownAmpMax"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.shake_amplitude_max = value


func _on_shakedown_freq_min_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer12/ShakedownFreqMin"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.shake_frequency_min = value


func _on_shakedown_freq_max_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer13/ShakedownFreqMax"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.shake_frequency_max = value

func _on_shake_duration_min_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer14/ShakeDurationMin"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.shake_duration_min = value

func _on_shake_duration_max_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer15/ShakeDurationMax"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.shake_duration_max = value

func _on_line_max_value_changed(value):
	var label = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer16/lineMax"
	var labelValor = label.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.tamanho_maximo_linha = value

func _on_padrao_pressed() -> void:
	padrao_atual_index += 1
	
	if padrao_atual_index >= recursos.size():
		padrao_atual_index = 0
	
	padrao_atual = recursos[padrao_atual_index]
	label_padrao.text = padrao_atual.name
	
	set_padrao_atual()

func _on_padrao_2_pressed() -> void:
	padrao_atual_index -= 1
	
	if padrao_atual_index < 0:
		padrao_atual_index = recursos.size() - 1
	
	padrao_atual = recursos[padrao_atual_index]
	label_padrao.text = padrao_atual.name
	
	set_padrao_atual()
	
func set_padrao_atual():
	#Jogador
	%ForcaMultiplicador.set_value_no_signal(padrao_atual.forca_multiplicador)
	%ForcaMaxima.set_value_no_signal(padrao_atual.forca_maxima)
	%DistanciaRaio.set_value_no_signal(padrao_atual.distancia_raio_visual)
	%Friccao.set_value_no_signal(padrao_atual.friccao_jogador)
	%Bounce.set_value_no_signal(padrao_atual.bounce_jogador)
	%LinearDamp.set_value_no_signal(padrao_atual.linear_damp_jogador)
	$"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer10/ShakedownAmpMin".set_value_no_signal(padrao_atual.shake_amplitude_min)
	$"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer11/ShakedownAmpMax".set_value_no_signal(padrao_atual.shake_amplitude_max)
	$"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer12/ShakedownFreqMin".set_value_no_signal(padrao_atual.shake_frequency_min)
	$"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer13/ShakedownFreqMax".set_value_no_signal(padrao_atual.shake_frequency_max)
	$"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer14/ShakeDurationMin".set_value_no_signal(padrao_atual.shake_duration_min)
	$"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer15/ShakeDurationMax".set_value_no_signal(padrao_atual.shake_duration_max)
	_on_forca_multiplicador_value_changed(padrao_atual.forca_multiplicador)
	_on_forca_maxima_value_changed(padrao_atual.forca_maxima)
	_on_distancia_raio_value_changed(padrao_atual.distancia_raio_visual)
	_on_friccao_value_changed(padrao_atual.friccao_jogador)
	_on_bounce_value_changed(padrao_atual.bounce_jogador)
	_on_linear_damp_value_changed(padrao_atual.linear_damp_jogador)
	_on_shakedown_amp_min_value_changed(padrao_atual.shake_amplitude_min)
	_on_shakedown_amp_max_value_changed(padrao_atual.shake_amplitude_max)
	_on_shakedown_freq_min_value_changed(padrao_atual.shake_frequency_min)
	_on_shakedown_freq_max_value_changed(padrao_atual.shake_frequency_max)
	_on_shake_duration_min_value_changed(padrao_atual.shake_duration_min)
	_on_shake_duration_max_value_changed(padrao_atual.shake_duration_max)
	
	#Bola
	%FriccaoBola.set_value_no_signal(padrao_atual.friccao_bola)
	%BounceBola.set_value_no_signal(padrao_atual.bounce_bola)
	%PesoBola.set_value_no_signal(padrao_atual.peso_bola)
	%LinearDampBola.set_value_no_signal(padrao_atual.linear_damp_bola)
	_on_friccao_bola_value_changed(padrao_atual.friccao_bola)
	_on_bounce_bola_value_changed(padrao_atual.bounce_bola)
	_on_peso_bola_value_changed(padrao_atual.peso_bola)
	_on_linear_damp_bola_value_changed(padrao_atual.linear_damp_bola)

func carregar_recursos():
	if not FileAccess.file_exists("user://padroes.json"):
		return
	var f = FileAccess.open("user://padroes.json", FileAccess.READ)
	var dados = JSON.parse_string(f.get_as_text())
	f.close()
	if not dados is Array:
		return
	for entrada in dados:
		var padrao = Padrao.new()
		padrao.name = entrada.get("name", "Custom")
		padrao.forca_multiplicador = entrada.get("forca_multiplicador", 0.0)
		padrao.forca_maxima = entrada.get("forca_maxima", 0.0)
		padrao.distancia_raio_visual = entrada.get("distancia_raio_visual", 0.0)
		padrao.friccao_jogador = entrada.get("friccao_jogador", 0.0)
		padrao.bounce_jogador = entrada.get("bounce_jogador", 0.0)
		padrao.linear_damp_jogador = entrada.get("linear_damp_jogador", 0.0)
		padrao.shake_amplitude_min = entrada.get("shake_amplitude_min", 0.0)
		padrao.shake_amplitude_max = entrada.get("shake_amplitude_max", 0.0)
		padrao.shake_frequency_min = entrada.get("shake_frequency_min", 0.0)
		padrao.shake_frequency_max = entrada.get("shake_frequency_max", 0.0)
		padrao.shake_duration_min = entrada.get("shake_duration_min", 0.0)
		padrao.shake_duration_max = entrada.get("shake_duration_max", 0.0)
		padrao.line_max = entrada.get("line_max", 0.0)
		padrao.friccao_bola = entrada.get("friccao_bola", 0.0)
		padrao.bounce_bola = entrada.get("bounce_bola", 0.0)
		padrao.peso_bola = entrada.get("peso_bola", 0.0)
		padrao.linear_damp_bola = entrada.get("linear_damp_bola", 0.0)
		recursos.append(padrao)

func _on_save_button_pressed():
	var dados: Array = []
	if FileAccess.file_exists("user://padroes.json"):
		var f = FileAccess.open("user://padroes.json", FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Array:
			dados = parsed
	
	var custom_count = 0
	for r in recursos:
		if r.name.begins_with("Custom"):
			custom_count += 1
	
	var novo_padrao = Padrao.new()
	novo_padrao.name = "Custom " + str(custom_count + 1)
	
	if Pecas_Jogo.size() > 0:
		var peca = Pecas_Jogo[0]
		novo_padrao.forca_multiplicador = peca.forca_multiplicador
		novo_padrao.forca_maxima = peca.forca_maxima
		novo_padrao.distancia_raio_visual = peca.raio_saida_pixels
		novo_padrao.friccao_jogador = peca.physics_material_override.friction
		novo_padrao.bounce_jogador = peca.physics_material_override.bounce
		novo_padrao.linear_damp_jogador = peca.linear_damp
		novo_padrao.shake_amplitude_min = peca.shake_amplitude_min
		novo_padrao.shake_amplitude_max = peca.shake_amplitude_max
		novo_padrao.shake_frequency_min = peca.shake_frequency_min
		novo_padrao.shake_frequency_max = peca.shake_frequency_max
		novo_padrao.shake_duration_min = peca.shake_duration_min
		novo_padrao.shake_duration_max = peca.shake_duration_max
		novo_padrao.line_max = peca.tamanho_maximo_linha
	
	if a_bola:
		novo_padrao.friccao_bola = a_bola.physics_material_override.friction
		novo_padrao.bounce_bola = a_bola.physics_material_override.bounce
		novo_padrao.peso_bola = a_bola.mass
		novo_padrao.linear_damp_bola = a_bola.linear_damp
	
	dados.append({
		"name": novo_padrao.name,
		"forca_multiplicador": novo_padrao.forca_multiplicador,
		"forca_maxima": novo_padrao.forca_maxima,
		"distancia_raio_visual": novo_padrao.distancia_raio_visual,
		"friccao_jogador": novo_padrao.friccao_jogador,
		"bounce_jogador": novo_padrao.bounce_jogador,
		"linear_damp_jogador": novo_padrao.linear_damp_jogador,
		"shake_amplitude_min": novo_padrao.shake_amplitude_min,
		"shake_amplitude_max": novo_padrao.shake_amplitude_max,
		"shake_frequency_min": novo_padrao.shake_frequency_min,
		"shake_frequency_max": novo_padrao.shake_frequency_max,
		"shake_duration_min": novo_padrao.shake_duration_min,
		"shake_duration_max": novo_padrao.shake_duration_max,
		"line_max": novo_padrao.line_max,
		"friccao_bola": novo_padrao.friccao_bola,
		"bounce_bola": novo_padrao.bounce_bola,
		"peso_bola": novo_padrao.peso_bola,
		"linear_damp_bola": novo_padrao.linear_damp_bola,
	})
	
	var f = FileAccess.open("user://padroes.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(dados, "\t"))
	f.close()
	
	recursos.append(novo_padrao)
	padrao_atual_index = recursos.size() - 1
	padrao_atual = novo_padrao
	label_padrao.text = novo_padrao.name
