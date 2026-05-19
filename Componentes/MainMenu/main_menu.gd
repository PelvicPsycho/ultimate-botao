extends Control

@onready var new_game_level: PackedScene = preload("res://MatchScene.tscn")

const MyTeamScene := preload("res://Componentes/MyTeam/elenco_menu_control.tscn") 

func _ready():
	print("=== CONFIGURAÇÕES CARREGADAS ===")
	print("Total de jogadores salvos no GameState: ", GameState.jogadores.size())

	if GameState.jogadores.size() == 0:
		print("Nenhum save encontrado. Carregando arquivos originais da pasta...")
		_carregar_da_pasta_padrao()
	else:
		print("✔ Jogadores carregados do save com sucesso!")
		for j in GameState.jogadores:
			print("\nJogador: ", j.nome)
			for s in j.slotsUpgrates:
				if s:
					print("  - ", s.nome)
				else:
					print("  - [Vazio]")

func _carregar_da_pasta_padrao():
	var pecas: Array = []
	var pasta := "res://Recursos/Teams/Grêmio/"
	
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
			if jogador is TeamPlayer and jogador.time and jogador.time.name == "Grêmio":
				pecas.append(jogador)
		f = dir.get_next()
		
	# Salva a lista carregada da pasta direto no Autoload
	GameState.jogadores = pecas

func _on_team_button_pressed() -> void:
	# Instancia a cena nova e adiciona na tela
	var tela = MyTeamScene.instantiate()
	get_parent().add_child(tela)
	
	self.visible = false

func _on_continue_button_pressed() -> void:
	favor_me_deletar()

func _on_new_game_button_pressed() -> void:
	if new_game_level != null:
		get_tree().change_scene_to_packed(new_game_level)
	else:
		favor_me_deletar()

func _on_settings_button_pressed() -> void:
	favor_me_deletar()

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
