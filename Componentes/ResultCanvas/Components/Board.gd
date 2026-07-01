extends TextureRect

@onready var homeScoreLabel = $Placar_Outline/Placar_BG_Esquerda/Placar_Label_Esquerda
@onready var awayScoreLabel = $Placar_Outline/Placar_BG_Direita/Placar_Label_Direita
@onready var homePanel = $Placar_Outline/Placar_BG_Esquerda
@onready var awayPanel = $Placar_Outline/Placar_BG_Direita
@export_range(0.0, 1.0) var lightened_value: float = 0.3

func _ready():
	homeScoreLabel.text = "0"
	awayScoreLabel.text = "0"

func change_Score_background_TextureRect_Colors(homeTeam_Color: Color, awayTeam_Color: Color) -> void:
	# Get colors from team info
	var homeTeam_gradient_texture = homePanel.texture as GradientTexture2D
	var awayTeam_gradient_texture = awayPanel.texture as GradientTexture2D
	
	var homeTeam_Color_light = homeTeam_Color.lightened(lightened_value)
	var awayTeam_Color_light = awayTeam_Color.lightened(lightened_value)
	
	# Update gradient with new colors
	homeTeam_gradient_texture.gradient.set_color(0, homeTeam_Color)
	homeTeam_gradient_texture.gradient.set_color(1, homeTeam_Color_light)
	
	awayTeam_gradient_texture.gradient.set_color(0, awayTeam_Color)
	awayTeam_gradient_texture.gradient.set_color(1, awayTeam_Color_light)
	
	# Update background TextureRect
	homePanel.texture = homeTeam_gradient_texture
	awayPanel.texture = awayTeam_gradient_texture

func setScore(homeScore: String, awayScore: String):
	homeScoreLabel.text = homeScore
	awayScoreLabel.text = awayScore

func _on_quit_btn_pressed():
	get_parent().get_parent()._set_match_paused(false)
	PvPManager.isPvpMatch = false
	PvPManager.teams.clear()
	get_tree().change_scene_to_file("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")

func _on_continue_btn_pressed():
	get_parent().get_parent()._set_match_paused(false)
	
	if PvPManager.isPvpMatch:
		get_tree().reload_current_scene()
		return
		
	if CupManager.isFinal:
		# Torneio concluído! Desbloqueia o próximo rank e volta ao menu
		CupManager._desbloquear_proximo_torneio()
		get_tree().change_scene_to_file("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")
	else:
		CupManager.nextCompetitor()
		get_tree().reload_current_scene()
