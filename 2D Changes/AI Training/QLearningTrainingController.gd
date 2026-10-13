extends Node2D
class_name QLearningTrainingController

const OBS_ANGULO_JOGADOR_BOLA = 8
const OBS_ANGULO_BOLA_GOL = 8
const OBS_DISTANCIA_JOGADOR_BOLA = 3
const OBS_DISTANCIA_BOLA_GOL = 3
const OBS_SPACE = OBS_ANGULO_JOGADOR_BOLA * OBS_ANGULO_BOLA_GOL * OBS_DISTANCIA_JOGADOR_BOLA * OBS_DISTANCIA_BOLA_GOL

const ACT_DIRECOES = 16
const ACT_FORCAS = 3
const ACT_SPACE = ACT_DIRECOES * ACT_FORCAS

const MAX_DIST_JOGADOR_BOLA = 1200
const MAX_DIST_BOLA_GOL = 1200

const MAX_STEPS = 1000

const Q_TABLE_PATH = "res://2D Changes/AI Training/q-table.dat"

var qnet: QLearning
var currentStep: int = 0

var dist_anterior = 0.0
var dist_anterior_jogador_bola = 0.0

var _waiting_physics = true

var currentEpisode: int = 0
var currentRewardSum: float = 0
var goalCounter: int 
var episodeCounter: int
var soma_reward_episodio: float = 0.0
var soma_steps: int = 0

@onready var _player = $"../PhysicsController/HomeTeam/HomeTeam_P5"
@onready var _ball = $"../PhysicsController/Balls/Ball2D_Tutorial"
@onready var _goal = $"../PhysicsController/Pitch2D_Tutorial_1/Pitch_Walls/AwayGoalWall_Line"
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
	
	MatchScene.connect("goalScored", onGoalScored)
	updateLabels()
	_reset_episode()

func _process(_delta: float) -> void:
	if _waiting_physics and _physics_settled():
		_waiting_physics = false
		updateEpisodeStatus2Label()
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
	currentStep += 1
	var reward = 0
	if currentStep >= MAX_STEPS:
		reward = -10.0
		currentRewardSum += reward
		qnet.predict(encodeState(), reward)
		_reset_episode()
		return

	# Recompensa por toque: o jogador tocou na bola neste passo?
	var reward_toque = 0.2 if _ball.lastTouch == _player else -0.1
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
	currentEpisode += 1
	episodeCounter += 1
	currentStep = 0
	soma_steps += currentStep
	if episodeCounter > 10:
		#updateLabels()
		qnet.save(Q_TABLE_PATH)
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
	var reward = 10.0
	currentRewardSum += reward
	goalCounter += 1
	qnet.predict(encodeState(), reward)
	print("goooooooooala onGoalScored")
	goalScoreOnArena.emit(_arenaIndex)
	#_reset_episode()

func updateLabels():
	updateEpisodeStatusLabel()
	updateEpisodeStatus2Label()

func updateEpisodeStatusLabel():
	var label = $"../CanvasLayer/Panel/Panel/Episode Stats"
	label.text = "Last 50 episodes: Avarage reward: %.3f | " % [soma_reward_episodio / episodeCounter] + "Avarage steps: %.1f | " % [float(soma_steps) / episodeCounter] + "Avarage goals: %.1f" % [float(goalCounter) / episodeCounter]

func updateEpisodeStatus2Label():
	var label = $"../CanvasLayer/Panel/Panel/Episode Stats2"
	label.text = "Current episode: %d | Total goals: %d | Current step: %d" % [currentEpisode, goalCounter, currentStep]

func _on_area_2d_body_exited(body):
	if body == _ball or body == _player:
		_reset_episode()
