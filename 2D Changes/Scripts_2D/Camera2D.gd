extends Camera2D

var allPieces
var allGoals

@export var zoom_speed_retorno: float = 6.0
@export var zoom_speed_arrasto: float = 2.5
@export var zoom_speed_foco: float = 1.5

@export var zoom_normal: Vector2 = Vector2.ONE
@export var zoom_arrasto_maximo: Vector2 = Vector2(0.78, 0.78)
@export var goal_shake_duration: float = 3.0
@export var goal_shake_amplitude: float = 36.0
@export var goal_shake_frequency: float = 48.0
@export var recoil_amplitude: float = 40.0 # NOVO: Força do coice da câmera
@export var recoil_recovery_speed: float = 10.0 # NOVO: Quão rápido a câmera se recupera do coice
@export var zoom_bola_foco: Vector2 = Vector2(2.0, 2.0)
@export var bola_track_speed: float = 1.0
@export var bola_min_velocidade: float = 30.0
@export var camera_return_speed: float = 3.0

var target_zoom: Vector2 = Vector2.ONE
var shake_active: bool = false
var shake_timer: float = 0.0
var shake_duration_atual: float = 0.0
var recoil_offset: Vector2 = Vector2.ZERO # NOVO: Variável que guarda o deslocamento do coice

var tracking_bola: bool = false
var is_dragging: bool = false # NOVO: Para sabermos se o jogador está ativamente a arrasta
var bola_rastreada = null
var posicao_base: Vector2

func _ready():
	allPieces = get_tree().get_nodes_in_group("Players")
	allGoals = get_tree().get_nodes_in_group("Goals")
	
	posicao_base = global_position
	
	if zoom == Vector2.ZERO:
		zoom = zoom_normal
	target_zoom = zoom
	
	for piece in allPieces:
		piece.connect("zoom_out_signal", StartZoomOut)
		piece.connect("zoom_in_signal", EndZoomOut)
		#piece.connect("maxForceShot", FlingCamera)
		if piece.has_signal("zoom_drag_signal"):
			piece.connect("zoom_drag_signal", UpdateDragZoom)

	for goal in allGoals:
		if goal.has_signal("gol"):
			goal.connect("gol", _on_goal_scored)
	
func _process(delta: float) -> void:
	# ... (Lógica de Zoom e Posição da Câmera) ...
	var current_zoom_speed: float
	if tracking_bola:
		current_zoom_speed = zoom_speed_foco
	elif is_dragging:
		current_zoom_speed = zoom_speed_arrasto
	else:
		# NOVO: Retorno suave para a posição central quando não está a rastrear a bola
		if global_position.distance_to(posicao_base) > 0.5:
			global_position = global_position.lerp(posicao_base, clamp(camera_return_speed * delta, 0.0, 1.0))
		else:
			global_position = posicao_base

	# NOVO: Amortece o coice da câmera de volta para o centro
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, clamp(recoil_recovery_speed * delta, 0.0, 1.0))

	var shake_offset_calc = Vector2.ZERO
	if shake_active:
		shake_timer += delta
		var progresso = clamp(shake_timer / max(shake_duration_atual, 0.001), 0.0, 1.0)
		var fade = 1.0 - progresso
		var t := shake_timer * goal_shake_frequency
		shake_offset_calc = Vector2(
			sin(t * 1.3) * goal_shake_amplitude * fade,
			cos(t * 1.7) * goal_shake_amplitude * fade
		)
		if shake_timer >= shake_duration_atual:
			shake_active = false
			shake_timer = 0.0
			
	# MÁGICA DO COICE: Soma o tremor aleatório (shake) com o empurrão direcional (recoil)
	offset = shake_offset_calc + recoil_offset

func FlingCamera(direcao: Vector2):
	# 1. Dá o solavanco exato na direção da peça
	recoil_offset = direcao.normalized() * recoil_amplitude
	
	# 2. Inicia um tremor bem curto para dar a sensação de impacto físico
	IniciarGoalShake(0.025)

func StartZoomOut(pos: Vector2):
	is_dragging = true
	target_zoom = zoom_normal
	
func EndZoomOut(pos: Vector2):
	is_dragging = false
	target_zoom = zoom_normal

func UpdateDragZoom(pos: Vector2, intensidade: float) -> void:
	target_zoom = zoom_normal.lerp(zoom_arrasto_maximo, clamp(intensidade, 0.0, 1.0))

func _on_goal_scored(_is_home: bool) -> void:
	_parar_rastreamento()
	IniciarGoalShake(goal_shake_duration)

func IniciarGoalShake(duracao: float = -1.0) -> void:
	shake_active = true
	shake_timer = 0.0
	shake_duration_atual = goal_shake_duration if duracao <= 0.0 else duracao

func _iniciar_rastreamento(bola) -> void:
	bola_rastreada = bola
	tracking_bola = true
	target_zoom = zoom_bola_foco

func _parar_rastreamento() -> void:
	if not tracking_bola:
		return
	tracking_bola = false
	bola_rastreada = null
	target_zoom = zoom_normal

func _on_area_home_body_entered(body):
	if body is PhysicsBall2D and body.current_velocity.length() >= bola_min_velocidade:
		_iniciar_rastreamento(body)

func _on_area_away_body_entered(body):
	if body is PhysicsBall2D and body.current_velocity.length() >= bola_min_velocidade:
		_iniciar_rastreamento(body)
