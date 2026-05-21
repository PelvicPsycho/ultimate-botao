extends PhysicsObject2D
class_name PhysicsPlayer2D

@export var debug: bool = true

# Object Proprieties
@export var min_force: float = 0.01
@export var max_force: float = 5

# Runtime Variables
var current_direction: Vector2 = Vector2.ZERO
var current_force: float = 0.0
var lerp_current_force: float = 0.0
var current_distance: float = 0
@export var max_distance: float = 1

var team: Team
@export var playerInfo: TeamPlayer

var canPlay: bool
var disabled: bool = false

signal clickedPiece(Piece: PhysicsPlayer)
signal turnPlayed

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)

func _ready() -> void:
	team = playerInfo.time
	is_pointer_inside_piece = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	start_Effects()
	
	Start_Aim()
	Start_Dragging_Line()
	Start_Velocity_Line()

func _process(delta: float) -> void:
	Draw_Aim()
	Draw_Dragging_Line()
	Draw_Velocity_Line()

#region Input
var is_dragging: bool = false
var is_pointer_inside_piece: bool = false #Mouse/dedo dentro da peça

var posicao_atual_toque_Tela: Vector2 = Vector2.ZERO
var posicao_inicial_toque_Tela: Vector2 = Vector2.ZERO
var posicao_final_toque_Tela: Vector2 = Vector2.ZERO

#var posicao_inicial_toque_Mundo3D: Vector2 = Vector2.ZERO
#var posicao_final_toque_Mundo3D: Vector2 = Vector2.ZERO

# Atualiza as variaveis de direcao_atual, distancia_atual e forca_atual
func MouseDragging_Update():
	current_direction = posicao_inicial_toque_Tela - posicao_final_toque_Tela
	current_distance = current_direction.length()

	current_direction = current_direction.normalized()
	
	if current_distance > max_distance:
		current_distance = max_distance
	
	lerp_current_force = current_distance / max_distance

	current_force = lerpf(min_force, max_force, lerp_current_force)
	
	if current_force > max_force:
		current_force = max_force

func _on_input_event(camera: Node, event: InputEvent, shape_idx: int) -> void:
	#if !canPlay or disabled:
		#return
	
	# Evento - clique do mouse esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			
			# Emite um sinal que o player foi clicado
			_on_player_pressed(position)
			
			# Zera variaveis
			current_direction = Vector2.ZERO
			
			Set_Current_Velocity(Vector2.ZERO)
			current_force = 0.0
			
			# Guarda a posição global do player
			posicao_inicial_toque_Tela = global_position

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	#if !canPlay or disabled:
		#return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# emite que a peça foi clicada
		clickedPiece.emit(self)
		_on_player_pressed(position)
		
		# pega a posição do mause na tela
		posicao_final_toque_Tela = get_global_mouse_position()
		
		MouseDragging_Update()

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
	Reset_Aim_Line()
	Reset_Dragging_Line()
	Reset_Velocity_Line()
	
	_on_player_released(position)
	is_dragging = false


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
	#print("Execute Action --------------------------------------------")
	Set_Current_Velocity(current_direction * current_force)
	
	#print("Current Force = ", current_force)
	#print("Velocity = ", current_velocity)
	
	_cancelar_interacao()
	turnPlayed.emit()
	

func move_object(_delta: float) -> void:
	var new_velocity = current_velocity * friction;
	Set_Current_Velocity(new_velocity)
	
	if abs(current_velocity.x) < 0.1 && abs(current_velocity.y) < 0.1:
		Set_Current_Velocity(Vector2.ZERO)
		is_moving = false
	else:
		is_moving = true
	
	#last_position = position
	#var newPos = position + (current_velocity * _delta)
	#position = newPos

#endregion

#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
#endregion

#region Others

func set_piece_available(pode_mexer: bool) -> void:
	if material == null:
		return
	if team.id == 1:
		material.set_shader_parameter("saturation", 0.958 if pode_mexer else 0.4)
		material.set_shader_parameter("light_max",  0.97 if pode_mexer else 1.0)
	else:
		material.set_shader_parameter("saturation", 0.958 if pode_mexer else 0.2)
		material.set_shader_parameter("light_max",  0.97 if pode_mexer else 1.0)

#endregion

#region Effects
@export var sprite2D_body: Sprite2D

func start_Effects() -> void:
	sprite2D_body.self_modulate = playerInfo.time.cor
#endregion

#region Lines
@export var aim_line2D: Line2D
@export var drag_line2D: Line2D
@export var velocity_line2D: Line2D

# Aim --------------------------
func Start_Aim() -> void:
	aim_line2D.add_point(Vector2.ZERO)
	aim_line2D.add_point(Vector2.ZERO)

func Draw_Aim() -> void:
	if is_dragging and !is_pointer_inside_piece:
		aim_line2D.visible = true
		
		var initial_point = aim_line2D.to_local(global_position)
		
		var final_point = aim_line2D.to_local(global_position + current_direction * (current_force / 10))
		
		aim_line2D.set_point_position(0, initial_point)
		aim_line2D.set_point_position(1, final_point)
	else:
		aim_line2D.visible = false

func Reset_Aim_Line() -> void:
	aim_line2D.set_point_position(0, Vector2.ZERO)
	aim_line2D.set_point_position(1, Vector2.ZERO)
	
# Drag --------------------------
func Start_Dragging_Line() -> void:
	drag_line2D.add_point(Vector2.ZERO)
	drag_line2D.add_point(Vector2.ZERO)
	

func Reset_Dragging_Line() -> void:
	drag_line2D.set_point_position(0, Vector2.ZERO)
	drag_line2D.set_point_position(1, Vector2.ZERO)

func Draw_Dragging_Line() -> void:
	if is_dragging:
		drag_line2D.visible = true
		
		var initial_point = drag_line2D.to_local(global_position)
		
		var final_point = drag_line2D.to_local(posicao_final_toque_Tela)
		
		drag_line2D.set_point_position(0, initial_point)
		drag_line2D.set_point_position(1, final_point)
	else:
		drag_line2D.visible = false

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
		
		var final_point = velocity_line2D.to_local(global_position + current_velocity )
		
		velocity_line2D.set_point_position(0, initial_point)
		velocity_line2D.set_point_position(1, final_point)
	else:
		velocity_line2D.visible = false
		
#endregion
