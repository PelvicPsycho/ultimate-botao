extends PhysicsObject2D
class_name PhysicsPlayer2D_Simulation_NoVisuals

@export var debug: bool = true

var index: int

@export var sprite2D_body: Sprite2D

# Runtime Variables
var current_direction: Vector2 = Vector2.ZERO
var current_force: float = 0.0
var lerp_current_force: float = 0.0
var current_distance: float = 0
@export var max_distance: float = 1

var team: Team
@export var playerInfo: TeamPlayer
var playerInfo_atual: TeamPlayer

var canPlay: bool
var disabled: bool = false

signal clickedPiece(Piece: PhysicsPlayer2D_Simulation)
signal turnPlayed

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)


func _ready() -> void:
	#team = playerInfo.time
	is_pointer_inside_piece = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if sprite2D_body == null:
		push_error("sprite2D_body é nulo")
		return
	
	#loadPlayerInfo(playerInfo)
	
	start_Effects()

	Start_Velocity_Line()

func loadPlayerInfo(plInfo):
	playerInfo_atual = plInfo.duplicate(true)
	playerInfo_atual.time = playerInfo.time
	playerInfo_atual.status_mudou.connect(atualizar_fisica_por_status)
	playerInfo_atual.status_mudou.connect(atualizar_peca_pelo_status)
	atualizar_peca_pelo_status()
	atualizar_fisica_por_status()
	
	Update_Values_With_StatusAtual()
	
	team = playerInfo.time
	
	sprite2D_body.self_modulate = team.cor
	
	#if debug:
		#print("Start friction = ", friction)
		#print("Start mass = ", mass)



func start_Effects() -> void:
	sprite2D_body.self_modulate = playerInfo.time.cor

func atualizar_fisica_por_status():
	# MASS
	# - Aumentar a massa torna a peça mais difícil de ser empurrada por outros
	mass = playerInfo_atual.basic_mass
	
	# Habilidade ativa - aumento_de_tamano
	if playerInfo_atual.aumento_de_tamano:
		mass = playerInfo_atual.basic_mass * 2.0   # dobra a massa

	# Habilidade ativa - diminui_de_tamano
	if playerInfo_atual.diminui_de_tamano:
		mass = playerInfo_atual.basic_mass * 0.5

	
	# FRICTION (0.0 to 1.0)
	# - é o quanto a peça perde velocidade enquanto se desloca
	# - quanto maior for o valor, - fricção será aplicado
	# - quanto menor for o valor, + fricção será aplicado
	friction = playerInfo_atual.basic_friction
	
	# Habilidade ativa - more_friction
	if playerInfo_atual.more_friction:
		friction = playerInfo_atual.basic_friction - 0.05

	# Habilidade ativa - less_friction
	if playerInfo_atual.less_friction:
		friction = playerInfo_atual.basic_friction + 0.05
	
	if friction >= 1:
		friction = 0.99


func atualizar_peca_pelo_status() -> void:
	if not is_instance_valid(playerInfo_atual): 
		return
	
	var CollisionShape2D_object = $CollisionShape2D
	var ShapeCast2D_Objects = $ShapeCast2D_Objects
	var ShapeCast2D_Walls = $ShapeCast2D_Walls
	
	if CollisionShape2D_object == null:
		print("Erro - Colisor Nulo")
		return
	
	# --- VISUAL DA PEÇA ---
	CollisionShape2D_object.scale = Vector2(1.0, 1.0)
	ShapeCast2D_Objects.scale = Vector2(1.0, 1.0)
	ShapeCast2D_Walls.scale = Vector2(1.0, 1.0)
	
	if playerInfo_atual.aumento_de_tamano:
		CollisionShape2D_object.scale = Vector2(1.5, 1.5)
		ShapeCast2D_Objects.scale = Vector2(1.5, 1.5)
		ShapeCast2D_Walls.scale = Vector2(1.5, 1.5)
	
	if playerInfo_atual.diminui_de_tamano:
		CollisionShape2D_object.scale = Vector2(0.5, 0.5)
		ShapeCast2D_Objects.scale = Vector2(0.5, 0.5)
		ShapeCast2D_Walls.scale = Vector2(0.5, 0.5)

func Update_Values_With_StatusAtual() -> void:
	mass = playerInfo_atual.basic_mass
	friction = playerInfo_atual.basic_friction

func _process(delta: float) -> void:
	Draw_Velocity_Line()

func definir_estado_visual(ativo: bool) -> void:
	self.canPlay = ativo


#region Input
var is_dragging: bool = false
var is_pointer_inside_piece: bool = false #Mouse/dedo dentro da peça

var posicao_atual_toque_Tela: Vector2 = Vector2.ZERO
var posicao_inicial_toque_Tela: Vector2 = Vector2.ZERO
var posicao_final_toque_Tela: Vector2 = Vector2.ZERO

#var posicao_inicial_toque_Mundo3D: Vector2 = Vector2.ZERO
#var posicao_final_toque_Mundo3D: Vector2 = Vector2.ZERO

# Atualiza as variaveis de direcao_atual, distancia_atual e forca_atual
func Mouse_Dragging_Update():
	current_direction = posicao_inicial_toque_Tela - posicao_final_toque_Tela
	current_distance = current_direction.length()
	
	if current_distance > max_distance:
		current_distance = max_distance
	
	current_direction = current_direction.normalized()
	
	lerp_current_force = current_distance / max_distance
	current_force = lerpf(playerInfo_atual.get_min_force(), playerInfo_atual.get_max_force(), lerp_current_force)
	
	if current_force > playerInfo_atual.basic_max_force:
		current_force = playerInfo_atual.basic_max_force
	
	#print("current_force = ", current_force)

func _on_input_event(camera: Node, event: InputEvent, shape_idx: int) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var player_que_quer_trocar = get_player_que_quer_trocar()
		#if player_que_quer_trocar:
			#player_que_quer_trocar.playerInfo_atual.troca_posicao_ativa = false
			#var temp = global_transform.origin
			#global_transform.origin = player_que_quer_trocar.global_transform.origin
			#player_que_quer_trocar.global_transform.origin = temp
			#return
	
	#if is_frozen():
		#return
	#
	#if !canPlay or disabled:
		#return
	
	# Evento - clique do mouse esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clickedPiece.emit(self)
			
			abrir_botoes_cartas()    # &lt;<&lt; ADICIONADO
			
			is_dragging = true
			
			# Emite um sinal que o player foi clicado
			_on_player_pressed(position)
			
			# Zera variaveis
			current_direction = Vector2.ZERO
			
			Set_Current_Velocity(Vector2.ZERO)
			current_force = 0.0
			
			direcao_travada = false
			
			# Guarda a posição global do player
			posicao_inicial_toque_Tela = global_position
		
		if Input.is_action_just_pressed("ui_focus_next"): # tecla TAB por padrão
			debug_status()

func _input(event: InputEvent) -> void:
	#if is_frozen():
		#return
		
	if not is_dragging:
		return
	
	#if !canPlay or disabled:
		#return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# emite que a peça foi clicada
		clickedPiece.emit(self)
		
		_on_player_pressed(position)
		
		# pega a posição do mouse na tela e atualiza força/distância antes dos efeitos visuais
		posicao_final_toque_Tela = get_global_mouse_position()
		Mouse_Dragging_Update()

	var is_mouse_release = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	var is_touch_release = event is InputEventScreenTouch and not event.pressed

	if is_mouse_release or is_touch_release:
		# Se soltou o dedo e ele estava FORA da peça, executa jogada!
		if not is_pointer_inside_piece:
			Execute_Action()
		# Se soltou o dedo EM CIMA da peça, cancela a jogada
		else:
			_cancelar_interacao()

# Função usada quando o jogador desiste da jogada (solta o mouse no centro)
func _cancelar_interacao() -> void:
	Reset_Velocity_Line()
	
	_on_player_released(position)
	is_dragging = false
	direcao_travada = false

func _on_mouse_entered() -> void:
	is_pointer_inside_piece = true

func _on_mouse_exited() -> void:
	is_pointer_inside_piece = false

func _on_player_pressed(pos: Vector2):
	zoom_out_signal.emit(pos)

func _on_player_released(pos: Vector2):
	zoom_in_signal.emit(pos)

func puxar_no_timeout():
	if not is_dragging:
		return

	if current_direction.length() > 5.0:
		Execute_Action()
	else:
		_cancelar_interacao()
		turnPlayed.emit()

#endregion

#region Movement
func Execute_Action() -> void:
	if is_frozen():
		return
	
	#Set_Current_Velocity(current_direction * current_force)
	
	_cancelar_interacao()
	turnPlayed.emit()

#endregion

#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
#endregion

#region Lines
@export var velocity_line2D: Line2D

# Velocity --------------------------
func Start_Velocity_Line() -> void:
	velocity_line2D.add_point(Vector2.ZERO)
	velocity_line2D.add_point(Vector2.ZERO)
	

func Reset_Velocity_Line() -> void:
	velocity_line2D.set_point_position(0, Vector2.ZERO)
	velocity_line2D.set_point_position(1, Vector2.ZERO)

func Draw_Velocity_Line() -> void:
	if is_moving:
		velocity_line2D.visible = true

		var initial_point = velocity_line2D.to_local(global_position)
		var final_point = velocity_line2D.to_local(global_position + current_velocity)
		
		velocity_line2D.set_point_position(0, initial_point)
		velocity_line2D.set_point_position(1, final_point)
	else:
		velocity_line2D.visible = false
		
#endregion

#region Cards

var painel_cartas: Control = null

var gerenciador_cartas: Control

var direcao_travada: bool = false


func is_frozen() -> bool:
	#return status_atual.disabilitado or status_atual.turnos_preso > 0
	return false

func debug_status():
	print("STATUS DEBUG → ", playerInfo.nome)
	print("  Força:", playerInfo_atual.forca)
	print("  PA:", playerInfo_atual.PA)
	print("  Slots:", playerInfo_atual.slotsUpgrates)
	print("  Buffs Ativos:", playerInfo_atual.duracao_dos_buffs)

func abrir_botoes_cartas():
	if painel_cartas == null:
		return
	
	var pos_tela: Vector2 = global_position
	# Ajuste fino da posição na tela
	pos_tela.x += 40
	pos_tela.y -= 20

	painel_cartas.position = pos_tela
	painel_cartas.visible = true
	painel_cartas.definir_piece(self)
	painel_cartas.definir_cartas(playerInfo.slotsUpgrates)
#endregion
