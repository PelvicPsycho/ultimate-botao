extends MarginContainer

# Ajuste os caminhos dos nós conforme a sua árvore exata dentro da carta
@export var label_titulo: Label
@export var label_rank: Label
@export var botao_aceitar: TextureButton
@export var botao_label: Label  # Label filho do TextureButton ("ACEITAR" / "BLOQUEADO")
@export var grey_texture: Texture

var cup_data: Cup
var esta_desbloqueado: bool = false

func setup(novo_cup: Cup):
	cup_data = novo_cup
	
	# Atualiza os textos visuais
	label_titulo.text = cup_data.cupName
	
	# Pega o nome do Enum (S, A, B...) em formato de String baseando-se no número salvo
	var letra_do_rank = Cup.CUP_RANK.keys()[cup_data.cupRank]
	label_rank.text = "Rank " + letra_do_rank
	
	# Verifica se este torneio está desbloqueado
	esta_desbloqueado = cup_data.cupName in GameState.torneios_desbloqueados

func definir_foco(ativo: bool):
	# Controla a visibilidade e estado do botão com base no foco e no desbloqueio
	botao_aceitar.visible = ativo
	
	# Procura o animador pelo nome da classe
	var animador = _obter_animador_do_botao()
	
	if ativo:
		if esta_desbloqueado:
			botao_aceitar.disabled = false
			if botao_label:
				botao_label.text = "ACEITAR"
			if animador:
				animador.esta_bloqueado = false # Libera a animação de hover
		else:
			botao_aceitar.disabled = true
			botao_aceitar.texture_normal = grey_texture
			if botao_label:
				botao_label.text = "BLOQUEADO"
			if animador:
				animador.esta_bloqueado = true # Trava a animação de hover
	else:
		botao_aceitar.disabled = true
		if animador:
			animador.esta_bloqueado = true # Trava a animação se não estiver em foco


func _on_texture_button_pressed() -> void:
	# Bloqueia torneios que ainda não foram desbloqueados
	if not esta_desbloqueado:
		print("🔒 Torneio bloqueado: ", cup_data.cupName)
		return
	
	# 1. Manda o CupManager preparar tudo e salvar o jogo
	CupManager.iniciar_torneio_selecionado(cup_data)
	
	# 2. A UI só se preocupa em mudar de tela
	#get_tree().change_scene_to_file("res://2D Changes/2D_Scenes/MatchScene2D.tscn")
	
	get_tree().change_scene_to_file("res://Componentes/Simulation_AI/Scenes/MatchScene2D_AI.tscn")

func _obter_animador_do_botao() -> AnimadorHover:
	for filho in botao_aceitar.get_children():
		if filho is AnimadorHover:
			return filho
	return null
