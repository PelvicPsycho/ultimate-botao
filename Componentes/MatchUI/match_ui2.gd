extends CanvasLayer

#@export var Score_Position_Node: Node2D

#@onready var dividerHome = $MarginContainer/Control/VBoxContainer/ScorePanel/MarginContainer/HBoxContainer/VBoxContainer/Panel
#@onready var dividerAway = $MarginContainer/Control/VBoxContainer/ScorePanel/MarginContainer/HBoxContainer/VBoxContainer/Panel2

#VARIÁVEIS/COMPONENTES DOS EMBLEMAS
@onready var textureRectHome = $MarginContainer/Control/EmblemaHome/TextureRect
@onready var emblemPanelHome = $MarginContainer/Control/EmblemaHome
@onready var textureRectAway = $MarginContainer/Control/EmblemaAway/TextureRect
@onready var emblemPanelAway = $MarginContainer/Control/EmblemaAway

#VARIÁVEIS/COMPONENTES DOS LANCES
@onready var shotsGroupHome = $MarginContainer/Control/MarginContainer/VBoxContainer
@onready var shotsCounterHome = $MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda
@onready var shotsPanelHome = $MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome
@onready var shotsDotsHomeLst = [$MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance3,$MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance2,$MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lance1] 
@onready var shotsLabelHome = $MarginContainer/Control/MarginContainer/VBoxContainer/Panel_LancesHome/MarginContainer/HBox_LancesEsquerda/Lances
@onready var shotsProgressBarHome = $MarginContainer/Control/MarginContainer/Control/ProgressBarLanceHome #$MarginContainer/Control/MarginContainer/VBoxContainer/ProgressBarLanceHome

@onready var shotsGroupAway = $MarginContainer/Control/MarginContainer/VBoxContainer2
@onready var shotsCounterAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita
@onready var shotsPanelAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway
@onready var shotsDotsAwayLst = [$MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance3,$MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance2,$MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lance1]
@onready var shotsLabelAway = $MarginContainer/Control/MarginContainer/VBoxContainer2/Panel_LancesAway/MarginContainer/HBox_LancesDireita/Lances
@onready var shotsProgressBarAway = $MarginContainer/Control/MarginContainer/Control/ProgressBarLanceAway #$MarginContainer/Control/MarginContainer/VBoxContainer2/ProgressBarLanceAway

var homeTeam: Team
var awayTeam: Team
var estado_shots_home: Array[bool] = []
var estado_shots_away: Array[bool] = []
var ultimo_time_posse: int = -1

@export var escala_painel_ativo: Vector2 = Vector2(1.0, 1.0)
@export var escala_painel_inativo: Vector2 = Vector2(0.75, 0.75)
@export var duracao_animacao_posse: float = 0.22

@export var TempoHome_Label: Label
@export var TempoAway_Label: Label

@export var NomeCorHome: TextureRect
@export var NomeCorAway: TextureRect
@export var NomeJogadorHome: Label
@export var NomeJogadorAway: Label

@export var contador_de_lances_home = Control
@export var contador_de_lances_away = Control

var contador_atual: Node = null

# Variáveis dos labels de tempo
var tempo_home_pos_inicial: Vector2
var tempo_away_pos_inicial: Vector2
var tempo_home_pos_final: Vector2
var tempo_away_pos_final: Vector2
var tween_home_entry: Tween
var tween_away_entry: Tween
var tween_home_pingpong: Tween
var tween_away_pingpong: Tween

# Variáveis dos painéis NomeCor
const NOME_HOME_POS_FORA: float = -330.0
const NOME_HOME_POS_DENTRO: float = 0.0
const NOME_AWAY_POS_FORA: float = 330.0
const NOME_AWAY_POS_DENTRO: float = 0.0
var tween_nome_home: Tween
var tween_nome_away: Tween

signal transicao_concluida

func disparar_animacao_de_turno(activeTeam: Team) -> void:
	var novo_contador = contador_de_lances_home if activeTeam == homeTeam else contador_de_lances_away
	
	if contador_atual == null:
		# Primeira vez: só entra o contador do time escolhido
		novo_contador.entrada_concluida.connect(_on_primeira_entrada.bind(novo_contador), CONNECT_ONE_SHOT)
		novo_contador.animar_entrada(activeTeam.cor)
	elif contador_atual == novo_contador:
		# Mesmo time (não deveria acontecer)
		transicao_concluida.emit()
	else:
		# Time diferente: sai o atual, depois entra o novo
		contador_atual.saida_concluida.connect(_on_saida_para_entrada.bind(novo_contador, activeTeam.cor), CONNECT_ONE_SHOT)
		contador_atual.animar_saida()

func _on_primeira_entrada(novo_contador: Node) -> void:
	contador_atual = novo_contador
	transicao_concluida.emit()

func _on_saida_para_entrada(novo_contador: Node, cor: Color) -> void:
	contador_atual = null
	novo_contador.entrada_concluida.connect(_on_entrada_final.bind(novo_contador), CONNECT_ONE_SHOT)
	novo_contador.animar_entrada(cor)

func _on_entrada_final(novo_contador: Node) -> void:
	contador_atual = novo_contador
	transicao_concluida.emit()

func _ready() -> void:
	_inicializar_estado_lances()
	_inicializar_tempo_labels()
	_inicializar_nome_cor_labels()
	#print("Score.global_position = ", Score.global_position)
	#print("Score_Position_Node.global_position = ", Score_Position_Node.global_position)
#
#func _process(delta: float) -> void:
	#Score.global_position = Score_Position_Node.global_position

func UI_start(home_team: Team, away_team: Team):
	
	self.homeTeam = home_team
	self.awayTeam = away_team
	
	changeEmblems()
	changeEmblemPanelBorderColor()
	changeShotsPanelBorderColor()
	#changeScoreColor()
	changeTimersColor()
	changeNomeCorColors()
	
func changeTimersColor():
	var style: StyleBoxFlat
	
	#style = shotsProgressBarHome.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	#style.bg_color = homeTeam.cor
	#shotsProgressBarHome.add_theme_stylebox_override("fill", style)
	ProgressBarHome_Middle_Texture.self_modulate = homeTeam.cor
	ProgressBarAway_Middle_Texture.self_modulate = awayTeam.cor
	
	#style = shotsProgressBarAway.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	#style.bg_color = awayTeam.cor
	#shotsProgressBarAway.add_theme_stylebox_override("fill", style)

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

#func changeScoreColor():
	#var style: StyleBoxFlat
	#
	#style = dividerHome.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	#style.bg_color = homeTeam.cor
	#dividerHome.add_theme_stylebox_override("panel", style)
	#
	#style = dividerAway.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	#style.bg_color = awayTeam.cor
	#dividerAway.add_theme_stylebox_override("panel", style)
	#
	#labelScoreHome.label_settings.font_color = homeTeam.cor
	#labelScoreAway.label_settings.font_color = awayTeam.cor

func colorir_turno(activeTeam: Team, turnCounter: int):
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

	# Ativa o segundo lance no contador quando turnCounter == 1
	if turnCounter == 1 and contador_atual:
		contador_atual.animar_segundo_lance(activeTeam == homeTeam)

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

func _atualizar_label_lance(isHome: float, time: float) -> void:
#	print("timer = ", time)
	var text = format_time(time)
	
	if isHome:
		text = format_time(time)
		ProgressBarHome_Time_Label.text = text
		
		text = format_time(ProgressBarHome_MaxTime_Label)
		ProgressBarAway_Time_Label.text = text
		
		update_progressbar_Home_position(ProgressBarHome_MaxTime_Label, time)
		reset_progressbar_Away_position()
	else:
		text = format_time(ProgressBarAway_MaxTime_Label)
		ProgressBarHome_Time_Label.text = text
		
		text = format_time(time)
		ProgressBarAway_Time_Label.text = text
		
		update_progressbar_Away_position(ProgressBarAway_MaxTime_Label, time)
		reset_progressbar_Home_position()

@export var AnimationP_Home: AnimationPlayer 
@export var ProgressBarHome_Value_Texture: TextureRect
@export var ProgressBarHome_Middle_Texture: TextureRect
@export var ProgressBarHome_Time_Label: Label
var ProgressBarHome_MaxTime_Label: float
@export var ProgressBarHome_InitalPosition: Vector2 = Vector2.ZERO
@export var ProgressBarHome_FinalPosition: Vector2 = Vector2.ZERO

@export var AnimationP_Away: AnimationPlayer 
@export var ProgressBarAway_Value_Texture: TextureRect
@export var ProgressBarAway_Middle_Texture: TextureRect
@export var ProgressBarAway_Time_Label: Label
var ProgressBarAway_MaxTime_Label: float
@export var ProgressBarAway_InitalPosition: Vector2 = Vector2.ZERO
@export var ProgressBarAway_FinalPosition: Vector2 = Vector2.ZERO

func play_match_start_animation() -> void:
	AnimationP_Home.play("Home_TimeBar_Start")

func update_progressbar_Home_position(maxtime: float, currenttime: float) -> void:
	var value_lerp = 1 - (currenttime / maxtime)
	var new_pos = ProgressBarHome_InitalPosition.lerp(ProgressBarHome_FinalPosition, value_lerp)
	ProgressBarHome_Value_Texture.position = new_pos

func reset_progressbar_Home_position() -> void:
	var tween = create_tween()
	# Moves the node's position to Vector2(500, 300) over 2 seconds
	tween.tween_property(ProgressBarHome_Value_Texture, "position", ProgressBarHome_InitalPosition, 1)


func update_progressbar_Away_position(maxtime: float, currenttime: float) -> void:
	var value_lerp = 1 - (currenttime / maxtime)
	var new_pos = ProgressBarAway_InitalPosition.lerp(ProgressBarAway_FinalPosition, value_lerp)
	ProgressBarAway_Value_Texture.position = new_pos

func reset_progressbar_Away_position() -> void:
	var tween = create_tween()
	# Moves the node's position to Vector2(500, 300) over 2 seconds
	tween.tween_property(ProgressBarAway_Value_Texture, "position", ProgressBarAway_InitalPosition, 1)

func play_progressbar_Animations(isHome: bool) -> void:
	if isHome:
		AnimationP_Home.play("Home_TimeBar_Activate")
		AnimationP_Away.play("Away_TimeBar_Deactivate")
		_animar_tempo_label_entrada(true)
		_animar_tempo_label_saida(false)
		_animar_nome_cor_entrada(true)
		_animar_nome_cor_saida(false)
	else:
		AnimationP_Home.play("Home_TimeBar_Deactivate")
		AnimationP_Away.play("Away_TimeBar_Activate")
		_animar_tempo_label_entrada(false)
		_animar_tempo_label_saida(true)
		_animar_nome_cor_entrada(false)
		_animar_nome_cor_saida(true)


func format_time(time_in_seconds: float) -> String:
	var time_in_seconds_ceil = ceilf(time_in_seconds)
	
	var minutes: int = int(time_in_seconds_ceil) / 60
	var seconds: int = int(time_in_seconds_ceil) % 60
	
	# "%02d" pads numbers with a leading zero if they are single digits
	return "%02d:%02d" % [minutes, seconds]

# ── Animação dos Labels de Tempo ──

func _inicializar_tempo_labels() -> void:
	var viewport_width = get_viewport().get_visible_rect().size.x
	
	if TempoHome_Label:
		tempo_home_pos_inicial = TempoHome_Label.position
		tempo_home_pos_final = Vector2(tempo_home_pos_inicial.x + 150, tempo_home_pos_inicial.y)
		TempoHome_Label.position.x = -TempoHome_Label.size.x * 2
	
	if TempoAway_Label:
		tempo_away_pos_inicial = TempoAway_Label.position
		tempo_away_pos_final = Vector2(tempo_away_pos_inicial.x - 150, tempo_away_pos_inicial.y)
		TempoAway_Label.position.x = viewport_width + TempoAway_Label.size.x * 2

func _animar_tempo_label_entrada(is_home: bool) -> void:
	var label = TempoHome_Label if is_home else TempoAway_Label
	var pos_inicial = tempo_home_pos_inicial if is_home else tempo_away_pos_inicial
	var pos_final = tempo_home_pos_final if is_home else tempo_away_pos_final
	
	if not label:
		return
	
	_matar_tweens_label(is_home)
	
	var tween = create_tween()
	if is_home:
		tween_home_entry = tween
	else:
		tween_away_entry = tween
	
	tween.tween_property(label, "position", pos_inicial, 1.5)
	tween.tween_callback(_iniciar_pingpong.bind(is_home))

func _iniciar_pingpong(is_home: bool) -> void:
	var label = TempoHome_Label if is_home else TempoAway_Label
	var pos_inicial = tempo_home_pos_inicial if is_home else tempo_away_pos_inicial
	var pos_final = tempo_home_pos_final if is_home else tempo_away_pos_final
	
	if not label:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "position", pos_final, 10.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position", pos_inicial, 10.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if is_home:
		tween_home_pingpong = tween
	else:
		tween_away_pingpong = tween

func _animar_tempo_label_saida(is_home: bool) -> void:
	var label = TempoHome_Label if is_home else TempoAway_Label
	
	if not label:
		return
	
	_matar_tweens_label(is_home)
	
	var target_x: float
	if is_home:
		target_x = -label.size.x * 2
	else:
		target_x = get_viewport().get_visible_rect().size.x + label.size.x * 2
	
	var tween = create_tween()
	tween.tween_property(label, "position:x", target_x, 1.0)

func _matar_tweens_label(is_home: bool) -> void:
	if is_home:
		if tween_home_entry:
			tween_home_entry.kill()
			tween_home_entry = null
		if tween_home_pingpong:
			tween_home_pingpong.kill()
			tween_home_pingpong = null
	else:
		if tween_away_entry:
			tween_away_entry.kill()
			tween_away_entry = null
		if tween_away_pingpong:
			tween_away_pingpong.kill()
			tween_away_pingpong = null

# ── Animação dos Painéis NomeCor ──

func _inicializar_nome_cor_labels() -> void:
	if NomeCorHome:
		NomeCorHome.position.x = NOME_HOME_POS_FORA
	if NomeCorAway:
		NomeCorAway.position.x = NOME_AWAY_POS_FORA

func changeNomeCorColors() -> void:
	if NomeCorHome:
		NomeCorHome.self_modulate = homeTeam.cor
	if NomeJogadorHome:
		#NomeJogadorHome.text = homeTeam.name
		NomeJogadorHome.texto_auto_ajustavel = homeTeam.name
	if NomeCorAway:
		NomeCorAway.self_modulate = awayTeam.cor
	if NomeJogadorAway:
		#NomeJogadorAway.text = awayTeam.name
		NomeJogadorAway.texto_auto_ajustavel = awayTeam.name

func _animar_nome_cor_entrada(is_home: bool) -> void:
	var panel = NomeCorHome if is_home else NomeCorAway
	if not panel:
		return
	
	_matar_tween_nome(is_home)
	
	var tween = create_tween()
	tween.tween_property(panel, "position:x", NOME_HOME_POS_DENTRO if is_home else NOME_AWAY_POS_DENTRO, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	if is_home:
		tween_nome_home = tween
	else:
		tween_nome_away = tween

func _animar_nome_cor_saida(is_home: bool) -> void:
	var panel = NomeCorHome if is_home else NomeCorAway
	if not panel:
		return
	
	_matar_tween_nome(is_home)
	
	var target = NOME_HOME_POS_FORA if is_home else NOME_AWAY_POS_FORA
	var tween = create_tween()
	tween.tween_property(panel, "position:x", target, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	if is_home:
		tween_nome_home = tween
	else:
		tween_nome_away = tween

func _matar_tween_nome(is_home: bool) -> void:
	if is_home:
		if tween_nome_home:
			tween_nome_home.kill()
			tween_nome_home = null
	else:
		if tween_nome_away:
			tween_nome_away.kill()
			tween_nome_away = null
