extends Control

# Variáveis exportadas para você alterar o tamanho base e espaçamento direto no Inspetor para ver como fica melhor

func _ready():
	pass

func _on_continue_button_pressed() -> void:
	favor_me_deletar()

func _on_new_game_button_pressed() -> void:
	favor_me_deletar()

func _on_team_button_pressed() -> void:
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
