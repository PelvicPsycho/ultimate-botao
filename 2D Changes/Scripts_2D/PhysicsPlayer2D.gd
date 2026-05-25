extends PhysicsObject2D
class_name PhysicsPlayer2D

@export var debug: bool = true

# Runtime Variables
var current_direction: Vector2 = Vector2.ZERO
var current_force: float = 0.0
var lerp_current_force: float = 0.0
var current_distance: float = 0
@export var max_distance: float = 1
signal carta_clicada(carta)
var dono: PhysicsPlayer2D
var team: Team
@export var playerInfo: TeamPlayer
var playerInfo_atual: TeamPlayer
static var last_piece_with_radial: PhysicsPlayer2D = null
var canPlay: bool
var disabled: bool = false

signal clickedPiece(Piece: PhysicsPlayer2D)
signal turnPlayed

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)

#region Sound variables
#Variáveis de sons
@export_group("Sons de Interação")
@export var audio_clique: AudioStream
@export var audio_tensao: AudioStream
@export var audio_chute_normal: AudioStream
@export var audio_chute_max: AudioStream
@export var audio_cancelar: AudioStream
# Variável para rastrear o som contínuo da puxada
var sfx_tensao_atual: AudioStreamPlayer
@onready var menu_radial := $MenuRadial
@export_group("Sons de Colisão")
@export var audio_impacto_peca: AudioStream
@export var audio_impacto_bola: AudioStream
@export var audio_impacto_parede: AudioStream
@export var audio_impacto_trave: AudioStream
#endregion

func _ready() -> void:
	team = playerInfo.time
	is_pointer_inside_piece = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	sprite2D_circulo_limite.visible = false
	sprite2D_circulo_limite.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	if sprite2D_body == null:
		push_error("sprite2D_body é nulo")
		return
	
	base_visual_position = sprite2D_body.position
	
	start_Effects()
	
	Start_Aim()
	Start_Dragging_Line()
	Start_Velocity_Line()

func loadPlayerInfo(plInfo):
	playerInfo_atual = plInfo.duplicate(true)
	playerInfo_atual.status_mudou.connect(atualizar_fisica_por_status)
	playerInfo_atual.status_mudou.connect(atualizar_peca_pelo_status)
	atualizar_peca_pelo_status()
	atualizar_fisica_por_status()
	
	Update_Values_With_StatusAtual()
	
	#if debug:
		#print("Start friction = ", friction)
		#print("Start mass = ", mass)


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
	
	# --- VISUAL DO CÍRCULO ---
	if is_instance_valid(sprite2D_circulo_limite):
		var nova_escala: float = playerInfo_atual.escala_maxima_circulo_normal
		
		# Verifica em qual 'Degrau' de força o jogador está
		if playerInfo_atual.level_force < playerInfo_atual.level_force_weak:
			nova_escala = playerInfo_atual.escala_maxima_circulo_fraco
		elif playerInfo_atual.level_force >= playerInfo_atual.level_force_strong:
			nova_escala = playerInfo_atual.escala_maxima_circulo_forte
		
		playerInfo_atual.escala_maxima_circulo_atual = nova_escala
		
		sprite2D_circulo_limite.scale = Vector2(nova_escala, nova_escala)

func Update_Values_With_StatusAtual() -> void:
	mass = playerInfo_atual.basic_mass
	friction = playerInfo_atual.basic_friction

func _process(delta: float) -> void:
	Draw_Aim()
	Draw_Dragging_Line()
	Draw_Velocity_Line()

	if shaking and sprite2D_body != null:
		shake_timer += delta

		var t := shake_timer * shake_frequency

		var offset := Vector2(
			sin(t * 1.7) * shake_amplitude,
			cos(t * 1.9) * shake_amplitude
		)

		sprite2D_body.position = base_visual_position + offset


	
func definir_estado_visual(ativo: bool) -> void:
	self.canPlay = ativo
	
	#var material_alvo = team.materialAtivo if ativo else team.materialInativo
	
	#if material_alvo:
		#mesh.material_override = material_alvo.duplicate()

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
	
	var current_circulo_scale = lerpf(0.1, playerInfo_atual.escala_maxima_circulo_atual, lerp_current_force)
	sprite2D_circulo_limite.scale = Vector2(current_circulo_scale, current_circulo_scale)
	
	if current_force > playerInfo_atual.basic_max_force:
		current_force = playerInfo_atual.basic_max_force
	
	#print("current_force = ", current_force)

func _on_input_event(camera: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
	
		var player_que_quer_trocar = get_player_que_quer_trocar()

		if player_que_quer_trocar:
			print("------ TROCA ------")
			print("ANTES SELF:", global_position)
			print("ANTES ALVO:", player_que_quer_trocar.global_position)
			
			var alvo := get_player_que_quer_trocar()
			current_velocity = Vector2.ZERO
			alvo.current_velocity = Vector2.ZERO
			player_que_quer_trocar.playerInfo_atual.troca_posicao_ativa = false
			var temp = global_position
			
			global_position = player_que_quer_trocar.global_position
			
			player_que_quer_trocar.global_position = temp
			
			print("DEPOIS SELF:", global_position)
			print("DEPOIS ALVO:", player_que_quer_trocar.global_position)
			print("--------------------")
			await get_tree().process_frame

			print("VISUAL SELF:", sprite2D_body.global_position)
			print("NODE SELF:", global_position)
			return
	if is_frozen():
		return
	
	if !canPlay or disabled:
		return
	
	# Evento - clique do mouse esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("Peça clicada! level_force: ", playerInfo_atual.level_force)

			clickedPiece.emit(self)

			abrir_botoes_cartas()    # &lt;<&lt; ADICIONADO
			
			is_dragging = true
			
			SoundMaster.play_sfx(audio_clique) #Toca o som de clique normal
			sfx_tensao_atual = SoundMaster.play_sfx(audio_tensao, 0.8) #Toca tensao e salva a ref
			
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
	if is_frozen():
		return
		
	if not is_dragging:
		return
	
	if !canPlay or disabled:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# emite que a peça foi clicada
		clickedPiece.emit(self)
		
		update_dragging_effects(event.position)
		
		_on_player_pressed(position)
		
		# pega a posição do mause na tela
		posicao_final_toque_Tela = get_global_mouse_position()
		
		Mouse_Dragging_Update()

	var is_mouse_release = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	var is_touch_release = event is InputEventScreenTouch and not event.pressed
	print('Pos peca  ', global_position,)
	if is_mouse_release or is_touch_release:
		# Se soltou o dedo e ele estava FORA da peça, executa jogada!
		if not is_pointer_inside_piece:
			Execute_Action()
		# Se soltou o dedo EM CIMA da peça, cancela a jogada
		else:
			_cancelar_interacao()

# Função usada quando o jogador desiste da jogada (solta o mouse no centro)
func _cancelar_interacao() -> void:
	if is_instance_valid(sfx_tensao_atual):
		sfx_tensao_atual.stop()
		
	SoundMaster.play_sfx(audio_cancelar)
	
	Reset_Aim_Line()
	Reset_Dragging_Line()
	Reset_Velocity_Line()
	
	_on_player_released(position)
	is_dragging = false
	direcao_travada = false
	sprite2D_circulo_limite.visible = false

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
		parar_shake()
		Execute_Action()
	else:
		parar_shake()
		_cancelar_interacao()
		turnPlayed.emit()

#endregion

#region Movement
func Execute_Action() -> void:
	if menu_radial and menu_radial.is_open:
		menu_radial.fechar()
	if is_frozen():
		return
	
	if is_instance_valid(sfx_tensao_atual): 
		sfx_tensao_atual.stop()
	
	var audio_tiro = audio_chute_normal
	if lerp_current_force >= 1: 
		audio_tiro = audio_chute_max
		
	SoundMaster.play_sfx(audio_tiro, randf_range(0.9, 1.1))
	
	Set_Current_Velocity(current_direction * current_force)
	
	#print("max_force = ", playerInfo_atual.get_max_force())
	#print("current_force = ", current_force)
	#print("current_velocity = ", current_velocity)
	#print("friction = ", friction)
	
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
@export var sprite2D_circulo_limite: Sprite2D

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
		
		var direction = (posicao_final_toque_Tela - global_position).normalized() * current_distance
		
		var initial_point = drag_line2D.to_local(global_position)
		
		var final_point = drag_line2D.to_local(global_position + direction)
		
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

#region Merge


var painel_cartas: Control = null

var gerenciador_cartas: Control

var direcao_travada: bool = false


#region Circulo Limite
func update_dragging_effects(posicao_atual: Vector2) -> void:
	if not is_pointer_inside_piece:
		sprite2D_circulo_limite.visible = true

		var porcentagem_forca = clamp(current_force / playerInfo_atual.basic_max_force, 0.0, 1.0)
		#Checa se o som existe e altera o pitch baseado na força (de 0.8x a 1.8x)
		if is_instance_valid(sfx_tensao_atual): 
			if not sfx_tensao_atual.playing:
				sfx_tensao_atual.play()
			sfx_tensao_atual.pitch_scale = lerp(0.8, 1.8, porcentagem_forca)
		
		#material_circulo.albedo_color.a = lerp(0.1, 0.6, porcentagem_forca)
		if porcentagem_forca >= 1.0:
			sprite2D_circulo_limite.self_modulate = Color(1.0, 0.2, 0.2, 0.8)
		else:
			sprite2D_circulo_limite.self_modulate = Color(1.0, 1.0, 1.0, lerp(0.1, 0.6, porcentagem_forca))
		
		_atualizar_shake_puxar(porcentagem_forca)
	else:
		# Se voltar a mira pro centro, para o som de tensão
		if is_instance_valid(sfx_tensao_atual):
			sfx_tensao_atual.stop()
		sprite2D_circulo_limite.visible = false
		parar_shake()
#endregion

#region Shake Effect
# Shake state
var shake_update_timer: float = 0.0
var color
var Specular_color
@export var shake_update_interval: float = 0.3
var shake_intensity_target: float = 0.0
var shake_intensity_current: float = 0.0
var shaking: bool = false
var shake_timer: float = 0.0
var shake_duration: float = 0.0
var shake_amplitude: float = 0.0
var shake_frequency: float = 0.0
var cooldown_timer: float = 0.0
var cooldown_duration: float = 0.1  # Cooldown curto para evitar disparos repetidos
var base_visual_position: Vector2 = Vector2.ZERO

@export var shake_amplitude_min: float = 0.001
@export var shake_amplitude_max: float = 0.01
@export var shake_frequency_min: float = 1
@export var shake_frequency_max: float = 30.0
@export var shake_duration_min: float = 0.05
@export var shake_duration_max: float = 0.12

func _atualizar_shake_puxar(intensidade: float) -> void:
	if sprite2D_body == null:
		return

	shake_intensity_target = intensidade
	shaking = true

	shake_update_timer += get_process_delta_time()

	if shake_update_timer < shake_update_interval:
		return

	shake_update_timer = 0.0

	if not shaking:
		shake_timer = 0.0
		shake_duration = lerpf(shake_duration_min, shake_duration_max, intensidade)

	shake_amplitude = lerpf(shake_amplitude_min, shake_amplitude_max, intensidade)
	shake_frequency = lerpf(shake_frequency_min, shake_frequency_max, intensidade)
	
func parar_shake() -> void:
	shaking = false
	shake_timer = 0.0
	if sprite2D_body != null:
		sprite2D_body.position = base_visual_position
#endregion

func is_frozen() -> bool:
	#return status_atual.disabilitado or status_atual.turnos_preso > 0
	return false

func get_player_que_quer_trocar() -> PhysicsPlayer2D:
	var players = get_tree().get_nodes_in_group("Players")
	
	for p in players:
		if p != self and p.playerInfo_atual.troca_posicao_ativa and p.canPlay:
			print('Pos peca  ', global_position,)
			return p
	return null

# ainda tenho que ver o que utilizo dessa função
#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#var total := state.get_contact_count()
	#if total <= 0:
		#return
	#
#
	#for i in range(total):
		#var collider := state.get_contact_collider_object(i)
		#if collider == null:
			#continue
	#
		#if collider.name.to_lower() == "pitch":
			#continue
		#if status_atual.empurra_aliados_ativo:
			#if collider is Player and collider.team == self.team:
				#status_atual.empurra_aliados_ativo = false
				#var minha_vel = state.get_contact_local_velocity_at_position(i)
				#var vel_outro = state.get_contact_collider_velocity_at_position(i)
				#var impulso_base = (minha_vel - vel_outro)
				#var impulso_final = impulso_base * status_atual.empurra_aliados_multiplicador
				#collider.apply_central_impulse(impulso_final)   
		#if status_atual.congelamento_ativo:
	#
	## só congela peças (Player), ignora bola, parede etc
			#if collider is Player:
#
		## aplica stun no ALVO (não no atacante)
				#collider.status_atual.turnos_preso = status_atual.ultima_carta_usada.duracao
				#collider.status_atual.disabilitado = true
				#collider.status_atual.status_mudou.emit()
#
		## limpa estado do atacante
				#status_atual.congelamento_ativo = false
#
				#print("=== CONGELAMENTO ATIVADO ===")
				#print("Alvo:", collider.playerInfo.nome)
				#print("Turnos preso:", collider.status_atual.turnos_preso)
#
		#continue  # interrompe processamento desse contato
				#
#
#
		#var collider_id := collider.get_instance_id()
		#if spark_cooldowns.has(collider_id) and spark_cooldowns[collider_id] > 0.0:
			#continue
		#
		##Som
		#if collider is Player:
			#if collider.spark_cooldowns.has(get_instance_id()) and collider.spark_cooldowns[get_instance_id()] > 0.0:
				#continue # Ele acordou e já tocou, então eu fico quieto.
#
		##(Velocidade Relativa)
		## Calcula exatamente o quão rápido um bateu de frente com o outro, ignorando o peso
		#var minha_vel = state.get_contact_local_velocity_at_position(i)
		#var vel_outro = state.get_contact_collider_velocity_at_position(i)
		#var forca_impacto = (minha_vel - vel_outro).length()
#
		## Ignora esbarrões lentos. Como agora é velocidade pura, .5 ou 1.0 é um bom limite
		#if forca_impacto > 0.2: 
			#var audio_escolhido: AudioStream = null
			#
			#if collider is Player:
				#audio_escolhido = audio_impacto_peca
			#elif collider is Ball or collider.is_in_group("Balls"):
				#audio_escolhido = audio_impacto_bola
			#elif collider is Goal or collider.is_in_group("GoleiraHitSom"):
				#audio_escolhido = audio_impacto_trave
			#else:
				#audio_escolhido = audio_impacto_parede
				#
			#if audio_escolhido != null:
				## Matemática do Volume baseada na Velocidade.
				#var forca_relativa = clamp(forca_impacto / 5.0, 0.0, 1.0) 
				#var volume_dinamico = lerp(-5.0, 2.0, forca_relativa)
				#
				#var pitch_dinamico = randf_range(0.85, 1.15)
##				print("Batida de forca: ", forca_impacto, " | Arquivo: ", audio_escolhido, " | Volume dB: ", volume_dinamico)
				#SoundMaster.play_sfx(audio_escolhido, pitch_dinamico, volume_dinamico)
#
		#var ponto_global := state.get_contact_collider_position(i)
##		print("colidiu com:", collider.name, " em:", ponto_global)
#
		#ativar_spark_no_ponto_global(ponto_global)
#
		#spark_cooldowns[collider_id] = 0.2
		#break
func _on_carta_do_radial(carta):
	print("CARTA CLICADA -> ", carta.nome)

	var ms = get_tree().root.get_node("MatchScene2d")
	ms.tentar_usar_carta(self, carta)

	# fechar radial no Player
	menu_radial.fechar()

	# opcional: marcar que jogou o turno
	turnPlayed.emit()
func debug_status():
	print("STATUS DEBUG → ", playerInfo.nome)
	print("  Força:", playerInfo_atual.forca)
	print("  PA:", playerInfo_atual.PA)
	print("  Slots:", playerInfo_atual.slotsUpgrates)
	print("  Buffs Ativos:", playerInfo_atual.duracao_dos_buffs)

func abrir_botoes_cartas():
	if PhysicsPlayer2D.last_piece_with_radial != null:
		if PhysicsPlayer2D.last_piece_with_radial != self:
			if PhysicsPlayer2D.last_piece_with_radial.menu_radial.is_open:
				PhysicsPlayer2D.last_piece_with_radial.menu_radial.fechar()
	var cartas = []
	for c in playerInfo_atual.slotsUpgrates:
		if c != null:
			cartas.append(c)
	menu_radial.definir_cartas(cartas)
	if not menu_radial.carta_clicada.is_connected(_on_carta_do_radial):
		menu_radial.carta_clicada.connect(_on_carta_do_radial)
	menu_radial.abrir()
	PhysicsPlayer2D.last_piece_with_radial = self
#endregion
