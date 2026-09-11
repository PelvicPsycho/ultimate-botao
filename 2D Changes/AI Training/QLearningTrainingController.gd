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

const MAX_DIST_JOGADOR_BOLA = 900
const MAX_DIST_BOLA_GOL = 1000

const MAX_STEPS = 10000

var qnet: QLearning
var currentStep: int = 0

var previousReward: float = 0.0

var dist_anterior = 0.0

var _waiting_physics = true

@onready var _player = $"../PhysicsController/HomeTeam/HomeTeam_P5"
@onready var _ball = $"../PhysicsController/Balls/Ball2D_Tutorial"
@onready var _goal = $"../PhysicsController/Pitch2D_Tutorial_1/Pitch_Walls/AwayGoalWall_Line"
@onready var MatchScene = $".."

func _ready():
	qnet = QLearning.new(OBS_SPACE, ACT_SPACE, true, true)
	await get_tree().process_frame
	
	qnet.learning_rate = 0.4              # alpha: velocidade de aprendizado (padrão 0.2)
	qnet.discounted_factor = 0.9          # gamma: peso de recompensas futuras (padrão 0.9)
	qnet.exploration_probability = 1.0    # epsilon inicial: começa explorando tudo (padrão 1.0)
	qnet.exploration_decreasing_decay = 0.01  # quanto epsilon cai a cada decay (padrão 0.01)
	qnet.min_exploration_probability = 0.01   # epsilon mínimo — nunca para de explorar (padrão 0.01)
	qnet.decay_per_steps = 100            # a cada quantos passos epsilon decai (padrão 100)
	
	MatchScene.connect("goalScored", onGoalScored)

func _process(_delta: float) -> void:
	if _waiting_physics and _physics_settled():
		_waiting_physics = false
		_step()

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

	if currentStep >= MAX_STEPS:
		var reward = -0.1
		qnet.predict(encodeState(), reward)
		_reset_episode()
		return

	# Recompensa por toque: o jogador tocou na bola neste passo?
	var reward_toque = 0.2 if _ball.lastTouch == _player else 0.0
	_ball.lastTouch = null  # limpa para não contar o mesmo toque duas vezes

	# Recompensa intermediária: bola ficou mais perto do gol?
	var dist_atual = _ball.global_position.distance_to(_goal.global_position)
	var reward_passo = clampf((dist_anterior - dist_atual) / 100.0, -0.1, 0.1)
	dist_anterior = dist_atual
	
	print("Reward atual: ", reward_toque + reward_passo)
	
	var action = qnet.predict(encodeState(), reward_toque + reward_passo)
	_apply_action(action)
	_waiting_physics = true

func _reset_episode() -> void:
	currentStep = 0
	previousReward = 0.0
	$"..".pickBallSpawn()
	$"..".pickPlayerSpawn()
	_waiting_physics = false
	call_deferred("_step")

func onGoalScored():
	var reward = 1.0
	previousReward = 1.0
	qnet.predict(encodeState(), reward)
	print("GOOOOL")
	_reset_episode()
