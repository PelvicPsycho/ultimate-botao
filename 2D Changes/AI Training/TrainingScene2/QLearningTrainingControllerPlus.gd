extends Node2D
class_name QLearningTrainingControllerPlus

const OBS_ANG_JOG_BOLA := 8
const OBS_DIST_JOG_BOLA := 3
const OBS_ANG_BOLA_GOL_ADV := 8
const OBS_DIST_BOLA_GOL_ADV := 3
const OBS_DIST_BOLA_GOL_OWN := 3
const OBS_PRESSAO_BOLA := 3
const OBS_LINHA_GOL_LIVRE := 2
const OBS_SPACE = OBS_ANG_JOG_BOLA \
	* OBS_DIST_JOG_BOLA \
	* OBS_ANG_BOLA_GOL_ADV \
	* OBS_DIST_BOLA_GOL_ADV \
	* OBS_DIST_BOLA_GOL_OWN \
	* OBS_PRESSAO_BOLA \
	* OBS_LINHA_GOL_LIVRE

const ACT_DIRECOES = 16
const ACT_FORCAS = 3
const ACT_SPACE = ACT_DIRECOES * ACT_FORCAS

const MAX_DIST_JOGADOR_BOLA = 1200
const MAX_DIST_BOLA_GOL = 1200
const MAX_DIST_PRESSAO := 700.0
const RISCO_BLOQUEIO_RAIO := 90.0

const MAX_STEPS = 1000

const Q_TABLE_PATH = "res://2D Changes/AI Training/q-table.dat"

var qnet: QLearning
var currentStep: int = 0

var dist_anterior = 0.0
var dist_anterior_self_gol = 0.0
var dist_anterior_jogador_bola = 0.0

var _waiting_physics = true

var currentEpisode: int = 0
var currentRewardSum: float = 0
var goalCounter: int 
var selfGoalCounter: int = 0
var episodeCounter: int
var stepCounter: int = 0
var touchCounter: int = 0

@onready var _player = $"../PhysicsController/HomeTeam/HomeTeam_P1"
@onready var _op1 = $"../PhysicsController/AwayTeam/AwayTeam_P1"
@onready var _ball = $"../PhysicsController/Balls/Ball2d"
@onready var _home_goal = $"../PhysicsController/Pitch/HomeGoal_2D/Marker2D"
@onready var _away_goal =  $"../PhysicsController/Pitch/AwayGoal_2D/Marker2D2"
@onready var MatchScene = $".."

signal goalScoreOnArena(arenaIndex:int)

func _ready():
	qnet = QLearning.new(OBS_SPACE, ACT_SPACE, true, true)
	#qnet.load(Q_TABLE_PATH)
	_shared_qtable = qnet.QTable
	#if _shared_qtable != null:
		#qnet.QTable = _shared_qtable
	await get_tree().process_frame
	
	goalCounter = 0
	episodeCounter = 0
	qnet.learning_rate = 0.4              # alpha: velocidade de aprendizado (padrão 0.2)
	qnet.discounted_factor = 0.8          # gamma: peso de recompensas futuras (padrão 0.9)
	qnet.exploration_probability = 1.0    # epsilon inicial: começa explorando tudo (padrão 1.0)
	qnet.exploration_decreasing_decay = 0.01  # quanto epsilon cai a cada decay (padrão 0.01)
	qnet.min_exploration_probability = 0.01   # epsilon mínimo — nunca para de explorar (padrão 0.01)
	qnet.decay_per_steps = 100            # a cada quantos passos epsilon decai (padrão 100)
	qnet.print_debug_info = false
	_reset_episode()

func _process(_delta: float) -> void:
	if _waiting_physics and _physics_settled():
		_waiting_physics = false
		_step()
		
var _shared_qtable: Matrix = null

func set_shared_qtable(table: Matrix) -> void:
	_shared_qtable = table
	if qnet != null:
		qnet.QTable = _shared_qtable

func _input(event):
	if event.is_action_pressed("restart"):
		_reset_episode()

func _physics_settled() -> bool:
	return _player.current_velocity.length() < 10.0 and _ball.current_velocity.length() < 10.0

#func encodeState():
	#var playerPos = _player.global_position
	#var ballPos = _ball.global_position
	#var goalPos = _home_goal.global_position
	#
	#var directionPlayerBall = ballPos - playerPos
	#var anglePlayerBall = 0
	#if directionPlayerBall.length() > 1.0:
		#anglePlayerBall = int(fposmod(directionPlayerBall.angle(), TAU) / TAU * OBS_ANGULO_JOGADOR_BOLA) % OBS_ANGULO_JOGADOR_BOLA
	#
	#var distancePlayerBall = clampi(int(playerPos.distance_to(ballPos)/ MAX_DIST_JOGADOR_BOLA * OBS_DISTANCIA_JOGADOR_BOLA), 0, OBS_DISTANCIA_JOGADOR_BOLA-1)
	#
	#var directionBallGoal = goalPos - ballPos
	#var angleBallGoal = 0
	#if directionBallGoal.length() > 1.0:
		#angleBallGoal = int(fposmod(directionBallGoal.angle(), TAU) / TAU * OBS_ANGULO_BOLA_GOL) % OBS_ANGULO_BOLA_GOL
	#
	#var distanceBallGoal = clampi(int(ballPos.distance_to(goalPos)/ MAX_DIST_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL), 0, OBS_DISTANCIA_BOLA_GOL-1)
	#
	#return anglePlayerBall  * (OBS_DISTANCIA_JOGADOR_BOLA * OBS_ANGULO_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL) + distancePlayerBall * (OBS_ANGULO_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL) + angleBallGoal  * OBS_DISTANCIA_BOLA_GOL + distanceBallGoal

func encodeStateV2(
	active_player: Node2D,
	ball: Node2D,
	goal_adv_pos: Vector2,
	goal_own_pos: Vector2,
	opponents: Array
	) -> int:
	var p: Vector2 = active_player.global_position
	var b: Vector2 = ball.global_position
	
	# 1) Ângulo jogador -> bola (8)
	var ang_jb := _angle_bin(b - p, OBS_ANG_JOG_BOLA)

	# 2) Distância jogador -> bola (3)
	var dist_jb := _dist_bin(p.distance_to(b), MAX_DIST_JOGADOR_BOLA, OBS_DIST_JOG_BOLA)

	# 3) Ângulo bola -> gol adversário (8)
	var ang_bg_adv := _angle_bin(goal_adv_pos - b, OBS_ANG_BOLA_GOL_ADV)

	# 4) Distância bola -> gol adversário (3)
	var dist_bg_adv := _dist_bin(b.distance_to(goal_adv_pos), MAX_DIST_BOLA_GOL, OBS_DIST_BOLA_GOL_ADV)

	# 5) Distância bola -> gol próprio (3)
	var dist_bg_own := _dist_bin(b.distance_to(goal_own_pos), MAX_DIST_BOLA_GOL, OBS_DIST_BOLA_GOL_OWN)

	# 6) Pressão adversária na bola = dist do adversário mais próximo da bola (3)
	var min_opp_ball := _nearest_opponent_distance_to_point(opponents, b, MAX_DIST_PRESSAO)
	var pressao_bola := _dist_bin(min_opp_ball, MAX_DIST_PRESSAO, OBS_PRESSAO_BOLA)

	# 7) Linha bola->gol adversário livre? (2)
	# 1 = livre, 0 = bloqueada
	var linha_livre := 1 if _is_line_to_goal_free(b, goal_adv_pos, opponents, RISCO_BLOQUEIO_RAIO) else 0

	# Flatten em índice único (base mista)
	# Ordem: [ang_jb][dist_jb][ang_bg_adv][dist_bg_adv][dist_bg_own][pressao_bola][linha_livre]
	var idx := ang_jb
	idx = idx * OBS_DIST_JOG_BOLA + dist_jb
	idx = idx * OBS_ANG_BOLA_GOL_ADV + ang_bg_adv
	idx = idx * OBS_DIST_BOLA_GOL_ADV + dist_bg_adv
	idx = idx * OBS_DIST_BOLA_GOL_OWN + dist_bg_own
	idx = idx * OBS_PRESSAO_BOLA + pressao_bola
	idx = idx * OBS_LINHA_GOL_LIVRE + linha_livre

	# idx ∈ [0, OBS_SPACE_V2 - 1]
	return idx


# =========================
# Helpers
# =========================

func _angle_bin(v: Vector2, bins: int) -> int:
	if v.length_squared() < 0.0001:
		return 0
	var a := fposmod(v.angle(), TAU) # [0, TAU)
	var bin := int(floor(a / TAU * bins))
	return clampi(bin, 0, bins - 1)

func _dist_bin(d: float, dmax: float, bins: int) -> int:
	var t := clampf(d / max(dmax, 0.0001), 0.0, 0.999999)
	var bin := int(floor(t * bins))
	return clampi(bin, 0, bins - 1)

func _nearest_opponent_distance_to_point(opponents: Array, point: Vector2, fallback_max: float) -> float:
	if opponents.is_empty():
		return fallback_max
	var best := INF
	for o in opponents:
		if o == null:
			continue
		var d = o.global_position.distance_to(point)
		if d < best:
			best = d
	return fallback_max if best == INF else best

func _is_line_to_goal_free(from: Vector2, to: Vector2, opponents: Array, block_radius: float) -> bool:
	var seg := to - from
	var seg_len2 := seg.length_squared()
	if seg_len2 < 0.0001:
		return true
	for o in opponents:
		if o == null:
			continue
		var c: Vector2 = o.global_position
		var t := clampf((c - from).dot(seg) / seg_len2, 0.0, 1.0)
		var closest := from + seg * t
		var d := c.distance_to(closest)
		if d <= block_radius:
			return false
	return true

func _apply_action(action_int: int) -> void:
	var dir_index   = float(action_int) / float(ACT_FORCAS)   # parte inteira: qual direção (0-15)
	var force_index = action_int % ACT_FORCAS   # resto: qual força (0-2)

	var angle = (float(dir_index) / ACT_DIRECOES) * TAU  # distribui 16 direções em 360°
	var direction = Vector2(cos(angle), sin(angle))

	var force_lerp = [0.3, 0.6, 1.0][force_index]  # fraco, médio, forte

	_player.Execute_Action_parameters(direction, force_lerp)

func _step() -> void:
	currentStep += 1
	stepCounter+=1
	var reward = 0
	if currentStep >= MAX_STEPS:
		reward = -10.0
		currentRewardSum += reward
		qnet.predict(encodeStateV2(_player, _ball, _away_goal.global_position, _home_goal.global_position, [_op1]), reward)
		_reset_episode()
		return

	# Recompensa por toque: o jogador tocou na bola neste passo?
	var reward_toque = 0.2 if _ball.lastTouch == _player else -0.1
	_ball.lastTouch = null  # limpa para não contar o mesmo toque duas vezes

	# Recompensa intermediária: bola ficou mais perto do gol?
	var dist_atual = _ball.global_position.distance_to(_away_goal.global_position)
	var reward_passo = 0.0
	if dist_anterior - dist_atual == 0:
		reward_passo = -0.05
	else:
		reward_passo = clampf((dist_anterior - dist_atual) / 1000.0, -0.1, 0.1)
	dist_anterior = dist_atual
	
	# Recompensa intermediária: jogador ficou mais perto da bola?
	var dist_atual_jogador_bola = _player.global_position.distance_to(_ball.global_position)
	var reward_jogador_bola = 0.0
	if dist_anterior_jogador_bola - dist_atual_jogador_bola == 0:
		reward_jogador_bola = -0.05
	else:
		reward_jogador_bola = clampf((dist_anterior_jogador_bola - dist_atual_jogador_bola) / 1000.0, -0.1, 0.1)
	dist_anterior_jogador_bola = dist_atual_jogador_bola
	
	# Recompensa intermediária: bola ficou mais perto do proprio gol?
	var dist_atual_ball_self_gol = _ball.global_position.distance_to(_home_goal.global_position)
	var reward_self_gol = 0.0
	if dist_anterior_self_gol - dist_atual_ball_self_gol == 0:
		reward_self_gol = -0.05
	else:
		reward_self_gol = clampf(-((dist_anterior_self_gol - dist_atual_ball_self_gol) / 1000.0), -0.1, 0.1)
	dist_anterior_self_gol = dist_atual_ball_self_gol
	
	
	reward = reward_toque + reward_passo + reward_jogador_bola + reward_self_gol
	#print("reward_toque: %f, reward_passo: %f, reward_jogador_bola: %f, reward_bola_proprio_gol: %f, reward total: %f" % [reward_toque, reward_passo, reward_jogador_bola, reward_self_gol, reward])
	currentRewardSum += reward
	var action = qnet.predict(encodeStateV2(_player, _ball, _away_goal.global_position, _home_goal.global_position, [_op1]), reward)
	_apply_action(action)
	if currentStep % 100 == 0:
		MatchScene.updateLabel(MatchScene.simulation, currentEpisode, currentStep, goalCounter, selfGoalCounter)
	_waiting_physics = true

func _reset_episode() -> void:
	currentEpisode += 1
	episodeCounter += 1
	currentStep = 0
	if episodeCounter > 10:
		#updateLabels()
		save_log()
		qnet.save(Q_TABLE_PATH)
		episodeCounter = 0
		stepCounter = 0
	MatchScene.respawn()
	MatchScene.updateLabel(MatchScene.simulation, currentEpisode, currentStep, goalCounter, selfGoalCounter)
	_waiting_physics = false
	call_deferred("_step")

func onGoalScored(_arenaIndex:int):
	var reward = 10.0
	currentRewardSum += reward
	goalCounter += 1
	qnet.predict(encodeStateV2(_player, _ball, _away_goal.global_position, _home_goal.global_position, [_op1]), reward)
	#print("goooooooooala onGoalScored")
	goalScoreOnArena.emit(_arenaIndex)
	#_reset_episode()

func _on_area_2d_body_exited(body):
	if body == _ball or body == _player:
		_reset_episode()

func _on_home_goal_2d_gol(_isHome):
	var reward = 10.0
	currentRewardSum += reward
	goalCounter += 1
	qnet.predict(encodeStateV2(_player, _ball, _away_goal.global_position, _home_goal.global_position, [_op1]), reward)
	#print("goooooooooala onGoalScored")
	#goalScoreOnArena.emit(MatchScene.simulation)
	_reset_episode()

func _on_away_goal_2d_gol(_isHome):
	var reward = -10.0
	currentRewardSum += reward
	selfGoalCounter += 1
	qnet.predict(encodeStateV2(_player, _ball, _away_goal.global_position, _home_goal.global_position, [_op1]), reward)
	#print("goooooooooala onGoalScored")
	#goalScoreOnArena.emit(MatchScene.simulation)
	_reset_episode()

func save_log():
	var file = FileAccess.open("res://TrainingLog.txt", FileAccess.WRITE)
	var goal_per_steps: float = float(goalCounter)/float(stepCounter)
	var goal_per_eps: float = float(goalCounter)/float(episodeCounter)
	var toucy_per_eps: float = float(touchCounter)/float(episodeCounter)
	var content: String = "
	-----------------------------/n
	SIMULATION %d/n
	Episode: %d/n
	Goal per steps: %f/n
	Goal per episodes: %f/n
	Touch per Steps: %f/n
	" % [MatchScene.simulation, currentEpisode, goal_per_steps, goal_per_eps, toucy_per_eps]
	file.store_string(content)
