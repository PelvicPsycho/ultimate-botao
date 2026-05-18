extends Control

@onready var new_game_level: PackedScene = preload("res://MatchScene.tscn")
const TelaCartasScene := preload("res://Componentes/MainMenu/TelaCartas.tscn")

func _ready():
	# tentar carregar save
	var dados = SaveManager.load_game()
	print("=== CONFIGURAÇÕES CARREGADAS ===")
	print("Total de jogadores salvos: ", GameState.jogadores.size())

	for j in GameState.jogadores:
		print("\nJogador:", j.nome)
		print("Foto:", j.foto)
		print("Slots:")
		for s in j.slotsUpgrates:
			print("  - ", s)
	if dados.has("players"):
		print("✔ Save encontrado, carregando jogadores...")

		GameState.jogadores.clear()

		for p in dados["players"]:
			var jog := TeamPlayer.new()
			jog.nome = p["nome"]
			jog.foto = load(p["foto"])

			jog.slotsUpgrates.resize(p["slots"].size())
			for i in p["slots"].size():
				var path = p["slots"][i]
				if path != null:
					jog.slotsUpgrates[i] = load(path)

			GameState.jogadores.append(jog)

		print("Jogadores restaurados do save:", GameState.jogadores.size())
	else:
		print("Nenhum save encontrado. Usando arquivos .tres normalmente.")



func _on_continue_button_pressed() -> void:
	favor_me_deletar()

func _on_new_game_button_pressed() -> void:
	if new_game_level != null:
		get_tree().change_scene_to_packed(new_game_level)
	else:
		favor_me_deletar()

func _on_team_button_pressed() -> void:
	abrir_tela_cartas()

func _on_settings_button_pressed() -> void:
	favor_me_deletar()

func abrir_tela_cartas():
	print("\n=== ABRINDO TELA DE CARTAS ===")

	var pecas: Array = []

	if GameState.jogadores.size() > 0:
		# carregar do SAVE
		print("✔ Usando jogadores do save")
		pecas = GameState.jogadores.duplicate()
	else:
		# carregar dos .tres
		var pasta := "res://Recursos/Teams/Grêmio/"
		print("LENDO PASTA:", pasta)

		var dir := DirAccess.open(pasta)
		if dir == null:
			print("ERRO -> Pasta NAO encontrada!")
			return

		dir.list_dir_begin()
		var f = dir.get_next()

		while f != "":
			if f.ends_with(".tres") or f.ends_with(".res"):
				var caminho = pasta + f
				var jogador = load(caminho)
				if jogador is TeamPlayer:
					if jogador.time and jogador.time.name == "Grêmio":
						pecas.append(jogador)
			f = dir.get_next()

	GameState.jogadores = pecas   # <- SALVA LOCAL

	var tela = TelaCartasScene.instantiate()
	get_parent().add_child(tela)
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var peca_scene := preload("res://Componentes/PlayerV2/peça.tscn")
	var container := tela.get_node("ContainerDePecas")

	for jogador in pecas:
		var peca = peca_scene.instantiate()
		peca.team_player = jogador
		container.add_child(peca)

	self.visible = false
	
func favor_me_deletar():
	var label = Label.new()
	label.text = "Error 404"
	var tamanho_fonte = randi_range(10, 64)
	label.add_theme_font_size_override("font_size", tamanho_fonte)
	add_child(label)
	label.pivot_offset = label.size / 2.0
	label.rotation = randf_range(0.0, TAU)

	var tamanho_tela = get_viewport_rect().size
	var pos_x = randf_range(0.0, tamanho_tela.x)
	var pos_y = randf_range(0.0, tamanho_tela.y)
	label.position = Vector2(pos_x, pos_y)


func _on_button_pressed() -> void:
	SaveManager.delete_save()
	pass # Replace with function body.
