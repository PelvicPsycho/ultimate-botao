extends CanvasLayer

var Pecas_Jogo: Array[PhysicsPlayer2D] = []
var a_bola: PhysicsBall2D

@onready var recursos: Array[Padrao] = [
	preload("res://Recursos/Padroes/Padrao_Pavin_Fisica2D.tres"),
	preload("res://Recursos/Padroes/Padrao.tres"),
	]

@onready var padrao_atual: Padrao = recursos[0] 

@onready var padrao_atual_index = 0

@onready var label_padrao = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/PadroesPerfis/Label_Padrao"

@onready var labelPosse = $"Control/CenterContainer/TabContainer - Abas/Debug/VboxDebug/HBoxContainer17/PosseHbox/Label_Posse"
var posseTypes = ["Original", "Simplified", "Interspersed", "Original short"]
var posseIndex = 0

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
	_sincronizar_sliders_com_player()
	_sincronizar_sliders_com_bola()
	
	label_padrao.text = padrao_atual.name
	set_padrao_atual()
	
	labelPosse.text = posseTypes[posseIndex]


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
	get_tree().paused = false  # Despausa antes de trocar de cena para o mouse funcionar
	get_tree().change_scene_to_file("res://Componentes/MainMenu/start_menu_canvas_layer.tscn")

func pegar_todas_pecas():
	Pecas_Jogo.clear()
	var nodes_pecas = get_tree().get_nodes_in_group("Players")
	for node in nodes_pecas:
		if node is PhysicsPlayer2D:
			Pecas_Jogo.append(node as PhysicsPlayer2D)

func _sincronizar_sliders_com_player() -> void:
	if Pecas_Jogo.is_empty():
		return
	var peca := Pecas_Jogo[0]
	if peca == null or peca.playerInfo_atual == null:
		return

	%ForcaMultiplicador.set_value_no_signal(peca.playerInfo_atual.basic_min_force)
	%ForcaMaxima.set_value_no_signal(peca.playerInfo_atual.basic_max_force)
	%DistanciaRaio.set_value_no_signal(peca.playerInfo_atual.basic_mass)
	%Friccao.set_value_no_signal(peca.playerInfo_atual.basic_friction)
	%Bounce.set_value_no_signal(peca.playerInfo_atual.basic_scale)

	_on_forca_multiplicador_value_changed(peca.playerInfo_atual.basic_min_force)
	_on_forca_maxima_value_changed(peca.playerInfo_atual.basic_max_force)
	_on_distancia_raio_value_changed(peca.playerInfo_atual.basic_mass)
	_on_friccao_value_changed(peca.playerInfo_atual.basic_friction)
	_on_bounce_value_changed(peca.playerInfo_atual.basic_scale)

func _atualizar_fisica_das_pecas() -> void:
	for peca in Pecas_Jogo:
		if peca == null or peca.playerInfo_atual == null:
			continue
		peca.atualizar_fisica_por_status()
		peca.atualizar_peca_pelo_status()

func _sincronizar_sliders_com_bola() -> void:
	if a_bola == null:
		return

	%PesoBola.set_value_no_signal(a_bola.basic_mass)
	%FriccaoBola.set_value_no_signal(a_bola.basic_friction)
	%BounceBola.set_value_no_signal(a_bola.basic_scale)

	_on_peso_bola_value_changed(a_bola.basic_mass)
	_on_friccao_bola_value_changed(a_bola.basic_friction)
	_on_bounce_bola_value_changed(a_bola.basic_scale)

func _atualizar_fisica_da_bola() -> void:
	if a_bola == null:
		return
	a_bola.mass = a_bola.basic_mass
	a_bola.friction = a_bola.basic_friction
	a_bola.scale = Vector2(a_bola.basic_scale, a_bola.basic_scale)
	a_bola.radius = (a_bola.global_position - a_bola.Object_Radius.global_position).length()

func pegar_a_bola():
	a_bola = get_tree().get_first_node_in_group("Balls")

func _on_forca_multiplicador_value_changed(value: float) -> void:
	var labelValor = %ForcaMultiplicador.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.playerInfo_atual.basic_min_force = value
	_atualizar_fisica_das_pecas()
	#print("forca_multiplicador - Not Updated to the physics 2D")

func _on_forca_maxima_value_changed(value: float) -> void:
	var labelValor = %ForcaMaxima.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	print("forca maxima value = ", value)
	for peca in Pecas_Jogo:
		peca.playerInfo_atual.basic_max_force = value
	_atualizar_fisica_das_pecas()

func _on_distancia_raio_value_changed(value: float) -> void:
	var labelValor = %DistanciaRaio.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.playerInfo_atual.basic_mass = value
	_atualizar_fisica_das_pecas()
	#print("distancia_raio - Not Updated to the physics 2D")

func _on_friccao_value_changed(value: float) -> void:
	var labelValor = %Friccao.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.playerInfo_atual.basic_friction = value
	_atualizar_fisica_das_pecas()

func _on_bounce_value_changed(value: float) -> void:
	var labelValor = %Bounce.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	for peca in Pecas_Jogo:
		peca.playerInfo_atual.basic_scale = value
		peca.default_sprite_scale = Vector2(value, value)
	_atualizar_fisica_das_pecas()
	print("player bounce - Not Updated to the physics 2D")

func _on_peso_bola_value_changed(value: float) -> void:
	var labelValor = %PesoBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.basic_mass = value
	_atualizar_fisica_da_bola()

func _on_bounce_bola_value_changed(value: float) -> void:
	var labelValor = %BounceBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.basic_scale = value
	_atualizar_fisica_da_bola()

func _on_linear_damp_bola_value_changed(value: float) -> void:
	var labelValor = %LinearDampBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	#a_bola.linear_damp = value
	#print("linear_damp_bola - Not Updated to the physics 2D")

func _on_friccao_bola_value_changed(value: float) -> void:
	var labelValor = %FriccaoBola.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.basic_friction = value
	_atualizar_fisica_da_bola()

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
	%ForcaMultiplicador.set_value_no_signal(padrao_atual.jogador_basic_min_force)
	%ForcaMaxima.set_value_no_signal(padrao_atual.jogador_basic_max_force)
	%DistanciaRaio.set_value_no_signal(padrao_atual.jogador_basic_mass)
	%Friccao.set_value_no_signal(padrao_atual.jogador_basic_friction)
	%Bounce.set_value_no_signal(padrao_atual.jogador_basic_scale)
	_on_forca_multiplicador_value_changed(padrao_atual.jogador_basic_min_force)
	_on_forca_maxima_value_changed(padrao_atual.jogador_basic_max_force)
	_on_distancia_raio_value_changed(padrao_atual.jogador_basic_mass)
	_on_friccao_value_changed(padrao_atual.jogador_basic_friction)
	_on_bounce_value_changed(padrao_atual.jogador_basic_scale)
	
	#Bola
	%FriccaoBola.set_value_no_signal(padrao_atual.bola_basic_friction)
	%BounceBola.set_value_no_signal(padrao_atual.bola_basic_scale)
	%PesoBola.set_value_no_signal(padrao_atual.bola_basic_mass)
	%BolaEscala.set_value_no_signal(padrao_atual.bola_basic_scale)
	_on_friccao_bola_value_changed(padrao_atual.bola_basic_friction)
	_on_bounce_bola_value_changed(padrao_atual.bola_basic_scale)
	_on_peso_bola_value_changed(padrao_atual.bola_basic_mass)
	_on_bola_escala_value_changed(padrao_atual.bola_basic_scale)

func carregar_recursos():
	if not FileAccess.file_exists("user://padroes.json"):
		return
	var f_custom_read = FileAccess.open("user://padroes.json", FileAccess.READ)
	var dados = JSON.parse_string(f_custom_read.get_as_text())
	f_custom_read.close()
	if not dados is Array:
		return
	for entrada in dados:
		var padrao = Padrao.new()
		padrao.name = entrada.get("name", "Custom")
		padrao.jogador_basic_min_force = entrada.get("jogador_basic_min_force", entrada.get("forca_multiplicador", 100.0))
		padrao.jogador_basic_max_force = entrada.get("jogador_basic_max_force", entrada.get("forca_maxima", 1000.0))
		padrao.jogador_basic_mass = entrada.get("jogador_basic_mass", entrada.get("distancia_raio_visual", 5.0))
		padrao.jogador_basic_friction = entrada.get("jogador_basic_friction", entrada.get("friccao_jogador", 0.98))
		padrao.jogador_basic_scale = entrada.get("jogador_basic_scale", entrada.get("bounce_jogador", 1.0))
		padrao.bola_basic_min_force = entrada.get("bola_basic_min_force", 100.0)
		padrao.bola_basic_max_force = entrada.get("bola_basic_max_force", 1000.0)
		padrao.bola_basic_mass = entrada.get("bola_basic_mass", entrada.get("peso_bola", 5.0))
		padrao.bola_basic_friction = entrada.get("bola_basic_friction", entrada.get("friccao_bola", 0.98))
		padrao.bola_basic_scale = entrada.get("bola_basic_scale", entrada.get("bounce_bola", 1.0))
		recursos.append(padrao)

func _on_save_button_pressed():
	var dados_salvos: Array = []
	if FileAccess.file_exists("user://padroes.json"):
		var arquivo_leitura = FileAccess.open("user://padroes.json", FileAccess.READ)
		var parsed = JSON.parse_string(arquivo_leitura.get_as_text())
		arquivo_leitura.close()
		if parsed is Array:
			dados_salvos = parsed

	var quantidade_custom = 0
	for recurso in recursos:
		if recurso.name.begins_with("Custom"):
			quantidade_custom += 1

	var novo_padrao = Padrao.new()
	novo_padrao.name = "Custom " + str(quantidade_custom + 1)

	if not Pecas_Jogo.is_empty() and Pecas_Jogo[0].playerInfo_atual != null:
		var peca = Pecas_Jogo[0]
		novo_padrao.jogador_basic_min_force = peca.playerInfo_atual.basic_min_force
		novo_padrao.jogador_basic_max_force = peca.playerInfo_atual.basic_max_force
		novo_padrao.jogador_basic_mass = peca.playerInfo_atual.basic_mass
		novo_padrao.jogador_basic_friction = peca.playerInfo_atual.basic_friction
		novo_padrao.jogador_basic_scale = peca.playerInfo_atual.basic_scale

	if a_bola:
		novo_padrao.bola_basic_min_force = a_bola.basic_min_force
		novo_padrao.bola_basic_max_force = a_bola.basic_max_force
		novo_padrao.bola_basic_mass = a_bola.basic_mass
		novo_padrao.bola_basic_friction = a_bola.basic_friction
		novo_padrao.bola_basic_scale = a_bola.basic_scale

	dados_salvos.append({
		"name": novo_padrao.name,
		"jogador_basic_min_force": novo_padrao.jogador_basic_min_force,
		"jogador_basic_max_force": novo_padrao.jogador_basic_max_force,
		"jogador_basic_mass": novo_padrao.jogador_basic_mass,
		"jogador_basic_friction": novo_padrao.jogador_basic_friction,
		"jogador_basic_scale": novo_padrao.jogador_basic_scale,
		"bola_basic_min_force": novo_padrao.bola_basic_min_force,
		"bola_basic_max_force": novo_padrao.bola_basic_max_force,
		"bola_basic_mass": novo_padrao.bola_basic_mass,
		"bola_basic_friction": novo_padrao.bola_basic_friction,
		"bola_basic_scale": novo_padrao.bola_basic_scale,
	})

	var arquivo_escrita = FileAccess.open("user://padroes.json", FileAccess.WRITE)
	arquivo_escrita.store_string(JSON.stringify(dados_salvos, "\t"))
	arquivo_escrita.close()

	recursos.append(novo_padrao)
	padrao_atual_index = recursos.size() - 1
	padrao_atual = novo_padrao
	label_padrao.text = novo_padrao.name


func _on_padrao_1_pressed():
	posseIndex -= 1
	if posseIndex < 0:
		posseIndex = posseTypes.size() - 1
	labelPosse.text = posseTypes[posseIndex]
	$"..".turnDecider = posseIndex
	print($"..".turnDecider)

func _on_posse_back_pressed():
	posseIndex += 1
	if posseIndex > posseTypes.size() - 1:
		posseIndex = 0
	labelPosse.text = posseTypes[posseIndex]
	$"..".turnDecider = posseIndex
	print($"..".turnDecider)


func _on_bola_escala_value_changed(value):
	var labelValor = %BolaEscala.get_parent().get_node("ValorSlider")
	labelValor.text = str(value)
	a_bola.basic_scale = value
	_atualizar_fisica_da_bola()


func _on_button_pressed() -> void:
	var matchscene = get_parent()
	matchscene.homeScore = 3
	matchscene._on_partida_acabou()
	
	pass # Replace with function body.
