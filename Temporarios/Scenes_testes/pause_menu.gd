extends CanvasLayer

var Pecas_Jogo: Array[Player] = []

func _ready():
	# Garante que o menu comece invisível quando o jogo roda
	pegar_todas_pecas()
	hide()
	print(Pecas_Jogo)

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
	if novo_estado:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
#	var pecas = get_tree().get_nodes_in_group("pecas")
	Pecas_Jogo.assign(get_tree().get_nodes_in_group("pecas"))
