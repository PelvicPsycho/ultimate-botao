extends Node
class_name PlacarController

#VARIÁVEIS/COMPONENTES DO PLACAR
@export var labelScoreHome: Label
@export var labelScoreAway: Label

@export var backgroundScoreHome: TextureRect
@export var backgroundScoreAway: TextureRect

@export_range(0.0, 1.0) var lightened_value: float = 0.3

@export var labelMatchTimer: Label

func change_Score_background_TextureRect_Colors(homeTeam_Color: Color, awayTeam_Color: Color) -> void:
	print("AAAAAAAAAA")
	# Get colors from team info
	var homeTeam_gradient_texture = backgroundScoreHome.texture as GradientTexture2D
	var awayTeam_gradient_texture = backgroundScoreAway.texture as GradientTexture2D
	
	var homeTeam_Color_light = homeTeam_Color.lightened(lightened_value)
	var awayTeam_Color_light = awayTeam_Color.lightened(lightened_value)
	
	# Update gradient with new colors
	homeTeam_gradient_texture.gradient.set_color(0, homeTeam_Color)
	homeTeam_gradient_texture.gradient.set_color(1, homeTeam_Color_light)
	
	awayTeam_gradient_texture.gradient.set_color(0, awayTeam_Color)
	awayTeam_gradient_texture.gradient.set_color(1, awayTeam_Color_light)
	
	# Update background TextureRect
	backgroundScoreHome.texture = homeTeam_gradient_texture
	backgroundScoreAway.texture = awayTeam_gradient_texture

func atualizar_placar(home_score: int, away_score: int) -> void:
	if labelScoreHome == null or labelScoreAway == null:
		push_warning("MatchUI: labels de placar não encontrados.")
		return
	
	print("home_score = ", home_score)
	print("away_score = ", away_score)
	labelScoreHome.text = str(home_score)
	labelScoreAway.text = str(away_score)

func atualizar_Match_Timer(time: float) -> void:
	if labelScoreHome == null or labelScoreAway == null:
		push_warning("MatchUI: labels de tempo não encontrados.")
		return
	
	#print("timer = ", time)
	var text = format_time(time)
	labelMatchTimer.text = text

func format_time(time_in_seconds: float) -> String:
	var minutes: int = int(time_in_seconds) / 60
	var seconds: int = int(time_in_seconds) % 60
	
	# "%02d" pads numbers with a leading zero if they are single digits
	return "%02d:%02d" % [minutes, seconds]
