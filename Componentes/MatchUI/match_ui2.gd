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
@onready var shotsGroupHome = $MarginContainer/Control/MarginContainer/VBoxContainer
@onready var shotsCounterHome = $MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda
@onready var shotsPanelHome = $MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome
@onready var shotsDotsHomeLst = [$MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance3,$MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance2,$MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance1] 
@onready var shotsLabelHome = $MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lances
@onready var shotsProgressBarHome = $MarginContainer/Control/MarginContainer/VBoxContainer/ProgressBarLanceHome

@onready var shotsGroupAway = $MarginContainer/Control/MarginContainer/VBoxContainer2
@onready var shotsCounterAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita
@onready var shotsPanelAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway
@onready var shotsDotsAwayLst = [$MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance3,$MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance2,$MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance1]
@onready var shotsLabelAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lances
@onready var shotsProgressBarAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/ProgressBarLanceAway

var homeTeam: Team
var awayTeam: Team
var estado_shots_home: Array[bool] = []
var estado_shots_away: Array[bool] = []
var ultimo_time_posse: int = -1

@export var escala_painel_ativo: Vector2 = Vector2(1.0, 1.0)
@export var escala_painel_inativo: Vector2 = Vector2(0.75, 0.75)
@export var duracao_animacao_posse: float = 0.22

func _ready() -> void:
	_inicializar_estado_lances()

func UI_start(home_team: Team, away_team: Team):
	
	self.homeTeam = home_team
	self.awayTeam = away_team
	
	changeEmblems()
	changeEmblemPanelBorderColor()
	changeShotsPanelBorderColor()
	changeScoreColor()
	changeTimersColor()
	
	var timerNode = $"../MatchTimer"
	if timerNode and timerNode.tipo_do_timer == 2:
		timeLabel.text = str(timerNode.totalShotsRemaining)

func changeTimersColor():
	var style: StyleBoxFlat
	
	style = shotsProgressBarHome.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	style.bg_color = homeTeam.cor
	shotsProgressBarHome.add_theme_stylebox_override("fill", style)
	
	style = shotsProgressBarAway.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	style.bg_color = awayTeam.cor
	shotsProgressBarAway.add_theme_stylebox_override("fill", style)

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
	_animar_paineis_posse(activeTeam)
	
	if activeTeam == homeTeam:
		# Pinta o time Esquerdo
		for i in range(shotsDotsHomeLst.size()):
			var ativo_home := i <= turnCounter - 1
			if i <= turnCounter-1:
				shotsDotsHomeLst[i].set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
				shotsDotsHomeLst[i].set_instance_shader_parameter("espessura_contorno", 2.0)
			else:
				shotsDotsHomeLst[i].set_instance_shader_parameter("cor_da_bolinha", activeTeam.cor)
				shotsDotsHomeLst[i].set_instance_shader_parameter("espessura_contorno", 0.0)
			_animar_bolinha_se_mudou(shotsDotsHomeLst[i], estado_shots_home, i, ativo_home)
				
		# Esconde o time Direito
		for i in range(shotsDotsAwayLst.size()):
			var bolinha = shotsDotsAwayLst[i]
			bolinha.set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
			bolinha.set_instance_shader_parameter("espessura_contorno", 0.0)
			_animar_bolinha_se_mudou(bolinha, estado_shots_away, i, false)
			
	else:
		# Pinta o time Direito
		for i in range(shotsDotsAwayLst.size()):
			var ativo_away := i <= turnCounter - 1
			if i <= turnCounter-1:
				shotsDotsAwayLst[i].set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
				shotsDotsAwayLst[i].set_instance_shader_parameter("espessura_contorno", 2.0)
			else:
				shotsDotsAwayLst[i].set_instance_shader_parameter("cor_da_bolinha", activeTeam.cor)
				shotsDotsAwayLst[i].set_instance_shader_parameter("espessura_contorno", 0.0)
			_animar_bolinha_se_mudou(shotsDotsAwayLst[i], estado_shots_away, i, ativo_away)
				
		# Esconde o time Esquerdo
		for i in range(shotsDotsHomeLst.size()):
			var bolinha = shotsDotsHomeLst[i]
			bolinha.set_instance_shader_parameter("cor_da_bolinha", Color("#ececec"))
			bolinha.set_instance_shader_parameter("espessura_contorno", 0.0)
			_animar_bolinha_se_mudou(bolinha, estado_shots_home, i, false)

func _inicializar_estado_lances() -> void:
	estado_shots_home.resize(shotsDotsHomeLst.size())
	estado_shots_away.resize(shotsDotsAwayLst.size())
	for i in range(estado_shots_home.size()):
		estado_shots_home[i] = false
	for i in range(estado_shots_away.size()):
		estado_shots_away[i] = false
	for bolinha in shotsDotsHomeLst:
		bolinha.pivot_offset = bolinha.size * 0.5
	for bolinha in shotsDotsAwayLst:
		bolinha.pivot_offset = bolinha.size * 0.5

func _animar_bolinha_se_mudou(bolinha: TextureRect, estado: Array[bool], idx: int, ativo: bool) -> void:
	if idx >= estado.size():
		return

	if estado[idx] == ativo:
		return

	estado[idx] = ativo
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	if ativo:
		bolinha.scale = Vector2(0.65, 0.65)
		tween.tween_property(bolinha, "scale", Vector2.ONE, 0.5)
	else:
		tween.tween_property(bolinha, "scale", Vector2(0.65, 0.65), 0.5)
		tween.tween_property(bolinha, "scale", Vector2.ONE, 0.5)

func _animar_paineis_posse(activeTeam: Team) -> void:
	var posse_atual := 0 if activeTeam == homeTeam else 1
	if ultimo_time_posse == posse_atual:
		return

	ultimo_time_posse = posse_atual
	shotsGroupHome.pivot_offset = shotsGroupHome.size * 0.5
	shotsGroupAway.pivot_offset = shotsGroupAway.size * 0.5

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	if posse_atual == 0:
		tween.tween_property(shotsGroupHome, "scale", escala_painel_ativo, duracao_animacao_posse)
		tween.tween_property(shotsGroupAway, "scale", escala_painel_inativo, duracao_animacao_posse)
		tween.tween_property(shotsGroupHome, "modulate", Color(1.0, 1.0, 1.0, 1.0), duracao_animacao_posse)
		tween.tween_property(shotsGroupAway, "modulate", Color(1.0, 1.0, 1.0, 0.5), duracao_animacao_posse)
	else:
		tween.tween_property(shotsGroupHome, "scale", escala_painel_inativo, duracao_animacao_posse)
		tween.tween_property(shotsGroupAway, "scale", escala_painel_ativo, duracao_animacao_posse)
		tween.tween_property(shotsGroupAway, "modulate", Color(1.0, 1.0, 1.0, 1.0), duracao_animacao_posse)
		tween.tween_property(shotsGroupHome, "modulate", Color(1.0, 1.0, 1.0, 0.5), duracao_animacao_posse)

func _atualizar_label_partida(time: float) -> void:
	progressBar.value = time
	var timerNode = $"../MatchTimer"
	if timerNode and timerNode.tipo_do_timer == 2:
		timeLabel.text = str(timerNode.totalShotsRemaining)

func _atualizar_label_lance(isHome: float, time: float) -> void:
	if isHome:
		shotsProgressBarHome.value = time
		shotsProgressBarAway.value = 0.0
	else:
		shotsProgressBarAway.value = time
		shotsProgressBarHome.value = 0.0

func atualizar_placar(home_score: int, away_score: int) -> void:
	if labelScoreHome == null or labelScoreAway == null:
		push_warning("MatchUI: labels de placar não encontrados.")
		return

	labelScoreHome.text = str(home_score)
	labelScoreAway.text = str(away_score)
