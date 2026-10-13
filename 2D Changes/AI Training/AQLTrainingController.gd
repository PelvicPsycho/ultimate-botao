extends Node2D
class_name AQLLearningTrainingController

const OBS_ANGULO_JOGADOR_BOLA = 8
const OBS_ANGULO_BOLA_GOL = 8
const OBS_DISTANCIA_JOGADOR_BOLA = 3
const OBS_DISTANCIA_BOLA_GOL = 3

const ACT_DIRECOES = 16
const ACT_FORCAS = 3
const ACT_SPACE = ACT_DIRECOES * ACT_FORCAS

const MAX_DIST_JOGADOR_BOLA = 1200
const MAX_DIST_BOLA_GOL = 1200
const MAX_STEPS = 1000
const Q_WEIGHTS_PATH = "res://2D Changes/AI Training/aql-weights.dat"

const NUM_FEATURES = 22 # 3 interações + 16 direções (one-hot) + 3 forças (one-hot)

var qnet: ApproximateQLearning
var currentStep: int = 1
var dist_anterior = 0.0
var dist_anterior_jogador_bola = 0.0
var _waiting_physics = true

var currentEpisode: int = 0
var currentRewardSum: float = 0
var goalCounter: int  = 0
var episodeCounter: int
var soma_reward_episodio: float = 0.0
var soma_steps: int = 0

signal goalScoreOnArena(arenaIndex:int)

@onready var _player = $"../PhysicsController/HomeTeam/HomeTeam_P5"
@onready var _ball = $"../PhysicsController/Balls/Ball2D_Tutorial"
@onready var _goal = $"../PhysicsController/Pitch2D_Tutorial_1/Pitch_Walls/AwayGoalWall_Line"
@onready var MatchScene = $".."

func _ready():
	# 3 interações semânticas + 16 direções (one-hot) + 3 forças (one-hot) = 22 pesos
	var num_features = 3 + ACT_DIRECOES + ACT_FORCAS
	qnet = ApproximateQLearning.new(num_features, ACT_SPACE)
	#qnet.load(Q_WEIGHTS_PATH)
	
	qnet.learning_rate = 0.4              # alpha: velocidade de aprendizado (padrão 0.2)
	qnet.discounted_factor = 0.8          # gamma: peso de recompensas futuras (padrão 0.9)
	qnet.exploration_probability = 1.0    # epsilon inicial: começa explorando tudo (padrão 1.0)
	qnet.exploration_decreasing_decay = 0.01  # quanto epsilon cai a cada decay (padrão 0.01)
	qnet.min_exploration_probability = 0.01   # epsilon mínimo — nunca para de explorar (padrão 0.01)
	qnet.decay_per_steps = 100            # a cada quantos passos epsilon decai (padrão 100)
	
	await get_tree().process_frame
	MatchScene.connect("goalScored", onGoalScored)
	updateLabels()
	_reset_episode()

func _process(_delta: float) -> void:
	if _waiting_physics and _physics_settled():
		_waiting_physics = false
		updateEpisodeStatus2Label()
		_step()

func _physics_settled() -> bool:
	return _player.current_velocity.length() < 10.0 and _ball.current_velocity.length() < 10.0

func _apply_action(action_int: int) -> void:
	var dir_index   = action_int / ACT_FORCAS
	var force_index = action_int % ACT_FORCAS
	var angle = (float(dir_index) / ACT_DIRECOES) * TAU
	var direction = Vector2(cos(angle), sin(angle))
	var force_lerp = [0.3, 0.6, 1.0][force_index]
	_player.Execute_Action_parameters(direction, force_lerp)

func _step() -> void:
	currentStep += 1
	var reward = 0
	
	if currentStep >= MAX_STEPS:
		reward = -10.0
		currentRewardSum += reward
		# is_terminal = true (Não tenta prever o futuro porque acabou)
		qnet.predict_aql(_get_features_for_action, reward, true)
		_reset_episode()
		return

	# Recompensas intermediárias (shaping)
	var reward_toque = 0.2 if _ball.lastTouch == _player else -0.1
	_ball.lastTouch = null

	var dist_atual = _ball.global_position.distance_to(_goal.global_position)
	var reward_passo = clampf((dist_anterior - dist_atual) / 1000.0, -0.1, 0.1) if dist_anterior - dist_atual != 0 else -0.05
	dist_anterior = dist_atual
	
	var dist_atual_jogador_bola = _player.global_position.distance_to(_ball.global_position)
	var reward_jogador_bola = clampf((dist_anterior_jogador_bola - dist_atual_jogador_bola) / 1000.0, -0.1, 0.1) if dist_anterior_jogador_bola - dist_atual_jogador_bola != 0 else -0.05
	dist_anterior_jogador_bola = dist_atual_jogador_bola
	
	reward = reward_toque + reward_passo + reward_jogador_bola
	currentRewardSum += reward
	
	# Passamos o ponteiro da função (Callable) pro AQL avaliar todas as ações possíveis
	var action = qnet.predict_aql(_get_features_for_action, reward, false)
	_apply_action(action)
	_waiting_physics = true

func set_shared_aql(shared_instance: ApproximateQLearning) -> void:
	qnet = shared_instance

func _reset_episode() -> void:
	currentEpisode += 1
	episodeCounter += 1
	
	if episodeCounter > 10:
		qnet.save(Q_WEIGHTS_PATH)
		episodeCounter = 0
		
	soma_steps += currentStep
	soma_reward_episodio = 0.0
	soma_steps = 0 
	currentStep = 1
	
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

func _get_features_for_action(action_int: int) -> Array[float]:
	var f: Array[float] = []
	
	# Calcula as distâncias e ângulos (mesmo código do seu encodeState)
	var playerPos = _player.global_position
	var ballPos = _ball.global_position
	var goalPos = _goal.global_position
	
	var dirPB = ballPos - playerPos
	var anglePB = int(fposmod(dirPB.angle(), TAU) / TAU * OBS_ANGULO_JOGADOR_BOLA) % OBS_ANGULO_JOGADOR_BOLA if dirPB.length() > 1.0 else 0
	var distPB = clampi(int(playerPos.distance_to(ballPos)/ MAX_DIST_JOGADOR_BOLA * OBS_DISTANCIA_JOGADOR_BOLA), 0, OBS_DISTANCIA_JOGADOR_BOLA-1)
	
	var dirBG = goalPos - ballPos
	var angleBG = int(fposmod(dirBG.angle(), TAU) / TAU * OBS_ANGULO_BOLA_GOL) % OBS_ANGULO_BOLA_GOL if dirBG.length() > 1.0 else 0
	
	# Desempacota a ação que está sendo testada
	var dir_index   = action_int / ACT_FORCAS
	var force_index = action_int % ACT_FORCAS

	# FEATURE 1: O chute aponta para a bola? (Interação)
	# Multiplicamos anglePB (0-7) por 2 para parear com dir_index (0-15)
	var is_kick_to_ball = 1.0 if abs(dir_index - (anglePB * 2)) <= 2 else 0.0
	f.append(is_kick_to_ball)
	
	# FEATURE 2: A bola aponta para o gol? (Interação)
	var is_kick_to_goal = 1.0 if abs(dir_index - (angleBG * 2)) <= 2 else 0.0
	f.append(is_kick_to_goal)
	
	# FEATURE 3: Força condiz com a distância? (Interação)
	var is_force_ok = 1.0 if force_index == distPB else 0.0
	f.append(is_force_ok)
	
	# FEATURES 4 a 19: One-Hot da Direção Escolhida
	for i in range(ACT_DIRECOES):
		f.append(1.0 if dir_index == i else 0.0)
		
	# FEATURES 20 a 22: One-Hot da Força Escolhida
	for i in range(ACT_FORCAS):
		f.append(1.0 if force_index == i else 0.0)
		
	return f

func onGoalScored(_arenaIndex:int):
	var reward = 10.0
	currentRewardSum += reward
	goalCounter += 1
	qnet.predict_aql(_get_features_for_action, reward, true) # is_terminal = true
	print("goooooooooala onGoalScored")
	goalScoreOnArena.emit(_arenaIndex)

func updateLabels():
	updateEpisodeStatusLabel()
	updateEpisodeStatus2Label()

func updateEpisodeStatusLabel():
	var label = $"../CanvasLayer/Panel/Panel/Episode Stats"
	if label: label.text = "Last 10 episodes: Avg reward: %.3f | Avg steps: %.1f | Avg goals: %.1f" % [soma_reward_episodio / max(1, episodeCounter), float(soma_steps) / max(1, episodeCounter), float(goalCounter) / max(1, episodeCounter)]

func updateEpisodeStatus2Label():
	var label = $"../CanvasLayer/Panel/Panel/Episode Stats2"
	if label: label.text = "Current episode: %d | Total goals: %d | Current step: %d" % [currentEpisode, goalCounter, currentStep]
