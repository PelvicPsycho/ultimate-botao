extends Node2D
class_name QLearningTrainingController

const OBS_ANGULO_JOGADOR_BOLA = 8
const OBS_ANGULO_BOLA_GOL = 8
const OBS_DISTANCIA_JOGADOR_BOLA = 3
const OBS_DISTANCIA_BOLA_GOL = 3

# Deve corresponder exatamente às quatro dimensões de encodeState().
const OBS_SPACE = OBS_ANGULO_JOGADOR_BOLA * OBS_DISTANCIA_JOGADOR_BOLA * OBS_ANGULO_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL

const ACT_DIRECOES = 16
const ACT_FORCAS = 3
const ACT_SPACE = ACT_DIRECOES * ACT_FORCAS

const MAX_DIST_JOGADOR_BOLA = 1200
const MAX_DIST_BOLA_GOL = 1200

const MAX_STEPS = 1000

const Q_TABLE_PATH = "user://q-table.dat"
const Q_TABLE_SCHEMA = "football-basic-v1"
const LEGACY_Q_TABLE_PATH = "res://2D Changes/AI Training/q-table.dat"
const QTableStorage = preload("res://2D Changes/AI Training/QTableStorage.gd")

var qnet: QLearning
var currentStep: int = 0

var dist_anterior = 0.0
var dist_anterior_jogador_bola = 0.0

var _waiting_physics = false
var _training_started := false
var _training_blocked := false
var _shared_qtable: Matrix
signal qtable_save_requested

var currentEpisode: int = 0
var currentRewardSum: float = 0
var goalCounter: int 
var stepCounter: int
var touchCounter: int
var episodeCounter: int
var soma_reward_episodio: float = 0.0
var soma_steps: int = 0

@onready var _player = $"../PhysicsController/HomeTeam/HomeTeam_P5"
@onready var _ball = $"../PhysicsController/Balls/Ball2D_Tutorial"
@onready var _goal = $"../PhysicsController/Pitch2D_Tutorial_1/Pitch_Walls/AwayGoalWall_Line"
@onready var MatchScene = $".."

signal goalScoreOnArena(arenaIndex:int)
@export var reuseQTable: bool = false

func _ready():
	qnet = QLearning.new(OBS_SPACE, ACT_SPACE, true, true)
	goalCounter = 0
	stepCounter = 0
	touchCounter = 0
	episodeCounter = 0
	qnet.learning_rate = 0.4              # alpha: velocidade de aprendizado (padrão 0.2)
	qnet.discounted_factor = 0.8          # gamma: peso de recompensas futuras (padrão 0.9)
	qnet.exploration_probability = 1.0    # epsilon inicial: começa explorando tudo (padrão 1.0)
	qnet.exploration_decreasing_decay = 0.01  # quanto epsilon cai a cada decay (padrão 0.01)
	qnet.min_exploration_probability = 0.01   # epsilon mínimo — nunca para de explorar (padrão 0.01)
	qnet.decay_per_steps = 100            # a cada quantos passos epsilon decai (padrão 100)
	qnet.print_debug_info = false
	
	MatchScene.connect("goalScored", onGoalScored)
	call_deferred("_start_training")

func _process(_delta: float) -> void:
	if _waiting_physics and _physics_settled():
		_waiting_physics = false
		updateEpisodeStatus2Label()
		_step()
		
# O ambiente injeta a matriz antes desta chamada deferred. Também funciona sozinho.
func _start_training() -> void:
	if _training_started or _training_blocked:
		return
	if _shared_qtable == null:
		set_shared_qtable(load_initial_qtable())
	_training_started = true
	_reset_episode()
	updateLabels()


func should_reuse_qtable() -> bool:
	return reuseQTable


func load_initial_qtable() -> Matrix:
	if should_reuse_qtable():
		var table := QTableStorage.load_table(Q_TABLE_PATH, OBS_SPACE, ACT_SPACE, Q_TABLE_SCHEMA)
		# Migra o arquivo antigo apenas quando ainda não existe um checkpoint novo.
		if table == null and not FileAccess.file_exists(Q_TABLE_PATH):
			table = QTableStorage.load_legacy_basic_table(LEGACY_Q_TABLE_PATH, OBS_SPACE, ACT_SPACE, Q_TABLE_SCHEMA)
		if table != null:
			return table
	return qnet.QTable


func set_shared_qtable(table: Matrix) -> void:
	assert(table != null and table.rows == OBS_SPACE and table.cols == ACT_SPACE)
	_shared_qtable = table
	qnet.QTable = table


# Getter sem I/O: nunca substitui a matriz já compartilhada.
func getQTable() -> Matrix:
	return _shared_qtable


func _save_qtable() -> void:
	if qtable_save_requested.has_connections():
		qtable_save_requested.emit()
	else:
		QTableStorage.save_table(Q_TABLE_PATH, _shared_qtable, Q_TABLE_SCHEMA)


func _input(event):
	if _training_started and event.is_action_pressed("restart"):
		_reset_episode()

func _physics_settled() -> bool:
	return _player.current_velocity.length() < 10.0 and _ball.current_velocity.length() < 10.0

func encodeState():
	var playerPos = _player.global_position
	var ballPos = _ball.global_position
	var goalPos = _goal.global_position
	
	var directionPlayerBall = ballPos - playerPos
	var anglePlayerBall = 0
	if directionPlayerBall.length() > 1.0:
		anglePlayerBall = int(fposmod(directionPlayerBall.angle(), TAU) / TAU * OBS_ANGULO_JOGADOR_BOLA) % OBS_ANGULO_JOGADOR_BOLA
	
	var distancePlayerBall = clampi(int(playerPos.distance_to(ballPos)/ MAX_DIST_JOGADOR_BOLA * OBS_DISTANCIA_JOGADOR_BOLA), 0, OBS_DISTANCIA_JOGADOR_BOLA-1)
	
	var directionBallGoal = goalPos - ballPos
	var angleBallGoal = 0
	if directionBallGoal.length() > 1.0:
		angleBallGoal = int(fposmod(directionBallGoal.angle(), TAU) / TAU * OBS_ANGULO_BOLA_GOL) % OBS_ANGULO_BOLA_GOL
	
	var distanceBallGoal = clampi(int(ballPos.distance_to(goalPos)/ MAX_DIST_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL), 0, OBS_DISTANCIA_BOLA_GOL-1)
	
	return anglePlayerBall  * (OBS_DISTANCIA_JOGADOR_BOLA * OBS_ANGULO_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL) + distancePlayerBall * (OBS_ANGULO_BOLA_GOL * OBS_DISTANCIA_BOLA_GOL) + angleBallGoal  * OBS_DISTANCIA_BOLA_GOL + distanceBallGoal

func _apply_action(action_int: int) -> void:
	var dir_index   = action_int / ACT_FORCAS   # parte inteira: qual direção (0-15)
	var force_index = action_int % ACT_FORCAS   # resto: qual força (0-2)

	var angle = (float(dir_index) / ACT_DIRECOES) * TAU  # distribui 16 direções em 360°
	var direction = Vector2(cos(angle), sin(angle))

	var force_lerp = [0.3, 0.6, 1.0][force_index]  # fraco, médio, forte

	_player.Execute_Action_parameters(direction, force_lerp)

func _step() -> void:
	if not _training_started:
		return
	currentStep += 1
	stepCounter+=1
	var reward = 0
	if currentStep >= MAX_STEPS:
		reward = -10.0
		currentRewardSum += reward
		qnet.predict(encodeState(), reward)
		_reset_episode()
		return

	# Recompensa por toque: o jogador tocou na bola neste passo?
	var reward_toque
	if _ball.lastTouch == _player:
		reward_toque = 0.2
		touchCounter+=1
	else:
		reward_toque = -0.1
	_ball.lastTouch = null  # limpa para não contar o mesmo toque duas vezes

	# Recompensa intermediária: bola ficou mais perto do gol?
	var dist_atual = _ball.global_position.distance_to(_goal.global_position)
	var reward_passo = 0.0
	if dist_anterior - dist_atual == 0:
		reward_passo = -0.05
	else:
		reward_passo = clampf((dist_anterior - dist_atual) / 1000.0, -0.1, 0.1)
	dist_anterior = dist_atual
	
	# Recompensa intermediária: bola ficou mais perto do gol?
	var dist_atual_jogador_bola = _player.global_position.distance_to(_ball.global_position)
	var reward_jogador_bola = 0.0
	if dist_anterior_jogador_bola - dist_atual_jogador_bola == 0:
		reward_jogador_bola = -0.05
	else:
		reward_jogador_bola = clampf((dist_anterior_jogador_bola - dist_atual_jogador_bola) / 1000.0, -0.1, 0.1)
	dist_anterior_jogador_bola = dist_atual_jogador_bola
	
	#print("reward_toque: %f, reward_passo: %f, reward_jogador_bola: %f" % [reward_toque, reward_passo, reward_jogador_bola])
	reward = reward_toque + reward_passo + reward_jogador_bola
	currentRewardSum += reward
	var action = qnet.predict(encodeState(), reward)
	_apply_action(action)
	_waiting_physics = true

func _reset_episode() -> void:
	if not _training_started:
		return
	qnet.previous_state = -100
	currentEpisode += 1
	episodeCounter += 1
	currentStep = 0
	soma_steps += currentStep
	if episodeCounter > 10:
		#updateLabels()
		save_log()
		_save_qtable()
		episodeCounter = 0
	soma_reward_episodio = 0.0
	soma_steps = 0 
	var ball_spawn = null
	var player_spawn = null
	while true:
		ball_spawn = $"..".pickBallSpawn()
		player_spawn = $"..".pickPlayerSpawn()
		if ball_spawn != null and player_spawn != null and ball_spawn != player_spawn:
			break
	_ball.position = ball_spawn.position
	_ball.Set_Current_Velocity(Vector2.ZERO)
	_player.position = player_spawn.position
	_waiting_physics = false
	call_deferred("_step")
	updateEpisodeStatus2Label()

func onGoalScored(_arenaIndex:int):
	if not _training_started:
		return
	var reward = 10.0
	currentRewardSum += reward
	goalCounter += 1
	qnet.predict(encodeState(), reward)
	#print("goooooooooala onGoalScored")
	goalScoreOnArena.emit(_arenaIndex)
	if not goalScoreOnArena.has_connections():
		_reset_episode()

func updateLabels():
	updateEpisodeStatusLabel()
	updateEpisodeStatus2Label()

func updateEpisodeStatusLabel():
	var label = $"../CanvasLayer/Panel/Panel/Episode Stats"
	label.text = "Last 50 episodes: Avarage reward: %.3f | " % [soma_reward_episodio / maxi(episodeCounter, 1)] + "Avarage steps: %.1f | " % [float(soma_steps) / maxi(episodeCounter, 1)] + "Avarage goals: %.1f" % [float(goalCounter) / maxi(episodeCounter, 1)]

func updateEpisodeStatus2Label():
	var label = $"../CanvasLayer/Panel/Panel/Episode Stats2"
	label.text = "Time:%d | Current episode: %d | Total goals: %d | Current step: %d" % [Time.get_ticks_msec()/1000, currentEpisode, goalCounter, currentStep]

func _on_area_2d_body_exited(body):
	if body == _ball or body == _player:
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
	Q-Table: %s
	" % [MatchScene.arenaIndex, currentEpisode, goal_per_steps, goal_per_eps, toucy_per_eps, str(qnet.QTable.data)]
	file.store_string(content)
