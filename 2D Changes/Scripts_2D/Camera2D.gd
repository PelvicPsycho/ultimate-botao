extends Camera2D

var allPieces
var allGoals

@export var zoom_speed: float = 6.0

@export var zoom_normal: Vector2 = Vector2.ONE
@export var zoom_arrasto_maximo: Vector2 = Vector2(0.78, 0.78)
@export var goal_shake_duration: float = 3.0
@export var goal_shake_amplitude: float = 36.0
@export var goal_shake_frequency: float = 48.0
@export var zoom_bola_foco: Vector2 = Vector2(2.0, 2.0)
@export var bola_track_speed: float = 5.0
@export var bola_min_velocidade: float = 30.0

var target_zoom: Vector2 = Vector2.ONE
var shake_active: bool = false
var shake_timer: float = 0.0
var shake_duration_atual: float = 0.0

var tracking_bola: bool = false
var bola_rastreada = null
var posicao_original: Vector2

func _ready():
	# Get all playable pieces
	allPieces = get_tree().get_nodes_in_group("Players")
	allGoals = get_tree().get_nodes_in_group("Goals")
	if zoom == Vector2.ZERO:
		zoom = zoom_normal
	target_zoom = zoom
	
	# Conect "StartZoomOut" and "EndZoomOut" to playable pieces signals
	for piece in allPieces:
		piece.connect("zoom_out_signal", StartZoomOut)
		piece.connect("zoom_in_signal", EndZoomOut)
		if piece.has_signal("zoom_drag_signal"):
			piece.connect("zoom_drag_signal", UpdateDragZoom)

	for goal in allGoals:
		if goal.has_signal("gol"):
			goal.connect("gol", _on_goal_scored)
		
func _process(delta: float) -> void:
	zoom = zoom.lerp(target_zoom, clamp(zoom_speed * delta, 0.0, 1.0))

	if tracking_bola:
		if is_instance_valid(bola_rastreada) and bola_rastreada.current_velocity.length() >= bola_min_velocidade:
			global_position = global_position.lerp(bola_rastreada.global_position, clamp(bola_track_speed * delta, 0.0, 1.0))
		else:
			_parar_rastreamento()

	if shake_active:
		shake_timer += delta
		var progresso = clamp(shake_timer / max(shake_duration_atual, 0.001), 0.0, 1.0)
		var fade = 1.0 - progresso
		var t := shake_timer * goal_shake_frequency
		offset = Vector2(
			sin(t * 1.3) * goal_shake_amplitude * fade,
			cos(t * 1.7) * goal_shake_amplitude * fade
		)
		if shake_timer >= shake_duration_atual:
			shake_active = false
			shake_timer = 0.0
			offset = Vector2.ZERO
	else:
		offset = Vector2.ZERO

func StartZoomOut(pos: Vector2):
	target_zoom = zoom_normal
	
func EndZoomOut(pos: Vector2):
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
	posicao_original = global_position
	target_zoom = zoom_bola_foco

func _parar_rastreamento() -> void:
	if not tracking_bola:
		return
	tracking_bola = false
	bola_rastreada = null
	target_zoom = zoom_normal
	global_position = posicao_original

func _on_area_home_body_entered(body):
	if body is PhysicsBall2D and body.current_velocity.length() >= bola_min_velocidade:
		_iniciar_rastreamento(body)

func _on_area_away_body_entered(body):
	if body is PhysicsBall2D and body.current_velocity.length() >= bola_min_velocidade:
		_iniciar_rastreamento(body)
