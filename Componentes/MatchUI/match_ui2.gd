extends CanvasLayer

#VARIÁVEIS/COMPONENTES DO PLACAR
@onready var labelScoreHome = $MarginContainer/Control/VBoxContainer/ScorePanel/MarginContainer/HBoxContainer/ScoreHome
@onready var labelScoreAway = $MarginContainer/Control/VBoxContainer/ScorePanel/MarginContainer/HBoxContainer/ScoreAway
@onready var dividerHome = $MarginContainer/Control/VBoxContainer/ScorePanel/MarginContainer/HBoxContainer/VBoxContainer/Panel
@onready var dividerAway = $MarginContainer/Control/VBoxContainer/ScorePanel/MarginContainer/HBoxContainer/VBoxContainer/Panel2

#VARIÁVEIS/COMPONENTES DOS EMBLEMAS
@onready var textureRectHome = $MarginContainer/Control/EmblemaHome/TextureRect
@onready var emblemPanelHome = $MarginContainer/Control/EmblemaHome
@onready var textureRectAway = $MarginContainer/Control/EmblemaAway/TextureRect
@onready var emblemPanelAway = $MarginContainer/Control/EmblemaAway

#VARIÁVEIS/COMPONENTES DO TIMER
@onready var progressBar = $MarginContainer/Control/VBoxContainer/TimerBar/ProgressBar
@onready var timeLabel = $MarginContainer/Control/VBoxContainer/TimerBar/ProgressBar/TimeLabel
@onready var timerPanel = $MarginContainer/Control/VBoxContainer/TimerBar

#VARIÁVEIS/COMPONENTES DOS LANCES
@onready var shotsCounterHome = $MarginContainer/Control/MarginContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda
@onready var shotsPanelHome = $MarginContainer/Control/MarginContainer/Panel_LancesHome
@onready var shotsDotsHomeLst = [$MarginContainer/Control/MarginContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance3,$MarginContainer/Control/MarginContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance2,$MarginContainer/Control/MarginContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance1] 
@onready var shotsLabelHome = $MarginContainer/Control/MarginContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lances
@onready var shotsCounterAway = $MarginContainer/Control/MarginContainer/Panel_LancesAway/MarginContainer/HBox_LancesDireita
@onready var shotsPanelAway = $MarginContainer/Control/MarginContainer/Panel_LancesAway
@onready var shotsDotsAwayLst = [$MarginContainer/Control/MarginContainer/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance3,$MarginContainer/Control/MarginContainer/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance2,$MarginContainer/Control/MarginContainer/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance1]
@onready var shotsLabelAway = $MarginContainer/Control/MarginContainer/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lances

var homeTeam: Team
var awayTeam: Team

func UI_start(homeTeam: Team, awayTeam: Team):
	
	self.homeTeam = homeTeam
	self.awayTeam = awayTeam
	
	changeEmblems()
	changeEmblemPanelBorderColor()
	changeShotsPanelBorderColor()
	changeScoreColor()

func changeEmblems():
	textureRectHome.texture = homeTeam.emblem
	textureRectAway.texture = awayTeam.emblem

func changeEmblemPanelBorderColor():
	var style: StyleBoxFlat
	
	style = emblemPanelHome.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = homeTeam.cor
	emblemPanelHome.add_theme_stylebox_override("panel", style)
	
	style = emblemPanelAway.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = awayTeam.cor
	emblemPanelAway.add_theme_stylebox_override("panel", style)

func changeShotsPanelBorderColor():
	var style: StyleBoxFlat
	
	style = shotsPanelHome.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = homeTeam.cor
	shotsPanelHome.add_theme_stylebox_override("panel", style)
	
	style = shotsPanelAway.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = awayTeam.cor
	shotsPanelAway.add_theme_stylebox_override("panel", style)
	
	shotsLabelHome.label_settings.font_color = homeTeam.cor
	shotsLabelAway.label_settings.font_color = awayTeam.cor

func changeScoreColor():
	var style: StyleBoxFlat
	
	style = dividerHome.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = homeTeam.cor
	dividerHome.add_theme_stylebox_override("panel", style)
	
	style = dividerAway.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = awayTeam.cor
	dividerAway.add_theme_stylebox_override("panel", style)
	
	labelScoreHome.label_settings.font_color = homeTeam.cor
	labelScoreAway.label_settings.font_color = awayTeam.cor

func colorir_turno(activeTeam: Team, turnCounter: int):
	var style: StyleBoxFlat
	
	style = timerPanel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = activeTeam.cor
	timerPanel.add_theme_stylebox_override("panel", style)
	
	timeLabel.label_settings.font_color = activeTeam.cor
	
	if activeTeam == homeTeam:
		# Pinta o time Esquerdo
		for i in range(shotsDotsHomeLst.size()):
			if i <= turnCounter-1:
				shotsDotsHomeLst[i].set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
				shotsDotsHomeLst[i].set_instance_shader_parameter("espessura_contorno", 2.0)
			else:
				shotsDotsHomeLst[i].set_instance_shader_parameter("cor_da_bolinha", activeTeam.cor)
				shotsDotsHomeLst[i].set_instance_shader_parameter("espessura_contorno", 0.0)
				
		# Esconde o time Direito
		for bolinha in shotsDotsAwayLst:
			bolinha.set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
			bolinha.set_instance_shader_parameter("espessura_contorno", 0.0)
			
	else:
		# Pinta o time Direito
		for i in range(shotsDotsAwayLst.size()):
			if i <= turnCounter-1:
				shotsDotsAwayLst[i].set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
				shotsDotsAwayLst[i].set_instance_shader_parameter("espessura_contorno", 2.0)
			else:
				shotsDotsAwayLst[i].set_instance_shader_parameter("cor_da_bolinha", activeTeam.cor)
				shotsDotsAwayLst[i].set_instance_shader_parameter("espessura_contorno", 0.0)
				
		# Esconde o time Esquerdo
		for bolinha in shotsDotsHomeLst:
			bolinha.set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
			bolinha.set_instance_shader_parameter("espessura_contorno", 0.0)

func _atualizar_label_partida(time: float) -> void:
	progressBar.value = time

func atualizar_placar(home_score: int, away_score: int) -> void:
	if labelScoreHome == null or labelScoreAway == null:
		push_warning("MatchUI: labels de placar não encontrados.")
		return

	labelScoreHome.text = str(home_score)
	labelScoreAway.text = str(away_score)
