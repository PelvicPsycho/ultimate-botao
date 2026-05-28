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
var efeitos_visuais_ativos: Dictionary = {}

var team: Team
@export var playerInfo: TeamPlayer
var playerInfo_atual: TeamPlayer
static var last_piece_with_radial: PhysicsPlayer2D = null
var canPlay: bool
var disabled: bool = false
var congelado: bool = false
@onready var impactParticles = preload("res://2D Changes/Components/Particles/ImpactParticles/ImpactParticles.tscn")
@export var intervalo_minimo_particula_impacto_ms: int = 80
var ultimo_tempo_particula_impacto_ms: int = -99999

@export_group("Tracing settings")
@export var maxLenght: int = 15
@onready var tracer2D = $Line2D_Trace

var hover_tween: Tween
@export var hover_scale_multiplier: float = 1.2
var deform_tween: Tween
var base_visual_rotation: float = 0.0

@export var drag_rotation_offset_degrees: float = 0.0

signal clickedPiece(Piece: PhysicsPlayer2D)
signal turnPlayed

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)
signal zoom_drag_signal(pos, intensidade)

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
var buff_tween: Tween
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
	default_visual_scale = sprite2D_body.scale
	base_visual_scale = default_visual_scale
	base_visual_rotation = sprite2D_body.rotation
	
	start_Effects()
	
	Start_Aim()
	Start_Dragging_Line()
	Start_Velocity_Line()
	
	tracer2D.clear_points()

func loadPlayerInfo(plInfo):
	playerInfo_atual = plInfo.duplicate(true)
	playerInfo_atual.status_mudou.connect(atualizar_fisica_por_status)
	playerInfo_atual.status_mudou.connect(atualizar_peca_pelo_status)
	atualizar_peca_pelo_status()
	atualizar_fisica_por_status()
	
	Update_Values_With_StatusAtual()

	sprite2D_body.self_modulate = team.cor
	tracer2D.self_modulate = team.cor
	
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
	# Usa a escala base do Inspector como tamanho normal da peça.
	var scale_multiplier: float = 1.0
	if playerInfo_atual.aumento_de_tamano:
		scale_multiplier = 2.0
	elif playerInfo_atual.diminui_de_tamano:
		scale_multiplier = 0.5

	var target_scale: Vector2 = default_visual_scale * scale_multiplier
	base_visual_scale = target_scale
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(CollisionShape2D_object, "scale", target_scale, 0.5)
	tween.tween_property(ShapeCast2D_Objects, "scale", target_scale, 0.5)
	tween.tween_property(ShapeCast2D_Walls, "scale", target_scale, 0.5)
	tween.tween_property(sprite2D_body, "scale", target_scale, 0.5)
	if playerInfo_atual.duracao_dos_buffs.is_empty():
		limpar_todos_efeitos_visuais()
	if playerInfo_atual.turnos_congelamento_armazenado > 0 or playerInfo_atual.disabilitado:
		sprite2D_body.self_modulate = Color(0.5, 0.8, 1.0) 
	else:
		sprite2D_body.self_modulate = team.cor # Volta ao normal
	if is_instance_valid(sprite2D_circulo_limite):
		var nova_escala: float = playerInfo_atual.escala_maxima_circulo_normal
		if playerInfo_atual.level_force < playerInfo_atual.level_force_weak:
			nova_escala = playerInfo_atual.escala_maxima_circulo_fraco
			
		elif playerInfo_atual.level_force >= playerInfo_atual.level_force_strong:
			nova_escala = playerInfo_atual.escala_maxima_circulo_forte
		_animar_buff_forca()
		playerInfo_atual.escala_maxima_circulo_atual = nova_escala
		
		sprite2D_circulo_limite.scale = Vector2(nova_escala, nova_escala)
	
func Update_Values_With_StatusAtual() -> void:
	mass = playerInfo_atual.basic_mass
	friction = playerInfo_atual.basic_friction

func _process(delta: float) -> void:
	var label = get_node_or_null("LabelPA")
	
	if label and playerInfo_atual:
		label.text = str(playerInfo_atual.PA)
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
	
	if current_force > 0.0:
		tracer2D.add_point(self.global_position)
		if tracer2D.get_point_count() > maxLenght:
			tracer2D.remove_point(0)
	else:
		if tracer2D.get_point_count() > 0:
			tracer2D.remove_point(0)

func _animar_hover(entrando: bool) -> void:
	
	if canPlay:
		if hover_tween and hover_tween.is_valid():
			hover_tween.kill()
		
	
		hover_tween = create_tween()
		var target_scale: Vector2 = base_visual_scale * hover_scale_multiplier if entrando else base_visual_scale
		var duration: float = 0.2
		hover_tween.tween_property(sprite2D_body, "scale", target_scale, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)	

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
	if current_distance > 2.0 and menu_radial and menu_radial.is_open:
		menu_radial.fechar()
	if current_distance > max_distance:
		current_distance = max_distance
	
	current_direction = current_direction.normalized()
	
	lerp_current_force = current_distance / max_distance
	current_force = lerpf(playerInfo_atual.get_min_force(), playerInfo_atual.get_max_force(), lerp_current_force)
	_atualizar_deformacao_arrasto()
	zoom_drag_signal.emit(global_position, lerp_current_force)
	
	var current_circulo_scale = lerpf(0.1, playerInfo_atual.escala_maxima_circulo_atual, lerp_current_force)
	sprite2D_circulo_limite.scale = Vector2(current_circulo_scale, current_circulo_scale)
	
	if current_force > playerInfo_atual.basic_max_force:
		current_force = playerInfo_atual.basic_max_force
	
	#print("current_force = ", current_force)

func _on_input_event(camera: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var player_que_quer_trocar = get_player_que_quer_trocar()
		if player_que_quer_trocar:
			var alvo: PhysicsPlayer2D = player_que_quer_trocar
			var pos_self: Vector2 = global_position
			var pos_alvo: Vector2 = alvo.global_position
			current_velocity = Vector2.ZERO
			alvo.current_velocity = Vector2.ZERO
			alvo.playerInfo_atual.troca_posicao_ativa = false
			sprite2D_body.top_level = true
			alvo.sprite2D_body.top_level = true
		
			sprite2D_body.global_position = pos_self
			alvo.sprite2D_body.global_position = pos_alvo
		
			global_position = Vector2(5000, 5000)
			alvo.global_position = Vector2(6000, 6000)
			var tw = create_tween().set_parallel(true)
			tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			var tempo = 0.4
			
			tw.tween_property(sprite2D_body, "global_position", pos_alvo, tempo)
			tw.tween_property(alvo.sprite2D_body, "global_position", pos_self, tempo)
			
			if sprite2D_body and alvo.sprite2D_body:
				var escala_base_self = sprite2D_body.scale
				var escala_base_alvo = alvo.sprite2D_body.scale
				
				tw.tween_property(sprite2D_body, "scale", escala_base_self * 1.2, tempo / 2.0)
				tw.tween_property(alvo.sprite2D_body, "scale", escala_base_alvo * 1.2, tempo / 2.0)
				tw.chain().tween_property(sprite2D_body, "scale", escala_base_self, tempo / 2.0)
				tw.tween_property(alvo.sprite2D_body, "scale", escala_base_alvo, tempo / 2.0)
				
			tw.chain().tween_callback(func():
				
				global_position = pos_alvo
				alvo.global_position = pos_self
				sprite2D_body.top_level = false
				alvo.sprite2D_body.top_level = false
				sprite2D_body.position = base_visual_position
				alvo.sprite2D_body.position = alvo.base_visual_position
			)
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
		
		_on_player_pressed(position)
		
		# pega a posição do mouse na tela e atualiza força/distância antes dos efeitos visuais
		posicao_final_toque_Tela = get_global_mouse_position()
		Mouse_Dragging_Update()
		update_dragging_effects(event.position)

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
	parar_shake()
	_retomar_formato_normal()
		
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
	_animar_hover(true)

func _on_mouse_exited() -> void:
	is_pointer_inside_piece = false
	_animar_hover(false)

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
	
	if abs(current_velocity.x) < 10 && abs(current_velocity.y) < 10:
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

	if not (object_collided is PhysicsPlayer2D):
		return
	
	if get_instance_id() > object_collided.get_instance_id():
		return
	if playerInfo_atual and playerInfo_atual.congelamento_ativo:
		if object_collided.has_method("aplicar_congelamento"):
			object_collided.aplicar_congelamento(playerInfo_atual.poder_congelar_turnos)
			playerInfo_atual.congelamento_ativo = false
				
	if playerInfo_atual and playerInfo_atual.empurra_aliados_ativo:
		# Verifica se quem bateu é do MESMO TIME (aliado)
		if object_collided.team == self.team:
			if object_collided.has_method("aplicar_empurrao"):
				# Passa a velocidade atual para dar o boost
				
				object_collided.aplicar_empurrao(self.current_velocity)
				# Gasta o poder após usar
				playerInfo_atual.empurra_aliados_ativo = false	
	var agora_ms := Time.get_ticks_msec()
	if agora_ms - ultimo_tempo_particula_impacto_ms < intervalo_minimo_particula_impacto_ms:
		return
	
	ultimo_tempo_particula_impacto_ms = agora_ms
	_instanciar_particula_impacto(collision_position)

func _instanciar_particula_impacto(posicao_colisao: Vector2) -> void:
	if impactParticles == null:
		return

	var nova_particula = impactParticles.instantiate()
	if nova_particula == null:
		return

	var parent_node: Node = get_tree().current_scene
	if parent_node == null:
		parent_node = get_tree().root
	parent_node.add_child(nova_particula)

	if nova_particula is Node2D:
		nova_particula.global_position = posicao_colisao

	if nova_particula is GPUParticles2D:
		var gpu := nova_particula as GPUParticles2D
		gpu.restart()
		gpu.emitting = true
		if gpu.has_signal("finished"):
			gpu.finished.connect(gpu.queue_free, CONNECT_ONE_SHOT)
		else:
			var tempo_gpu = max(gpu.lifetime, 0.05)
			get_tree().create_timer(tempo_gpu).timeout.connect(gpu.queue_free, CONNECT_ONE_SHOT)
		return

	if nova_particula is CPUParticles2D:
		var cpu := nova_particula as CPUParticles2D
		cpu.restart()
		cpu.emitting = true
		if cpu.has_signal("finished"):
			cpu.finished.connect(cpu.queue_free, CONNECT_ONE_SHOT)
		else:
			var tempo_cpu = max(cpu.lifetime, 0.05)
			get_tree().create_timer(tempo_cpu).timeout.connect(cpu.queue_free, CONNECT_ONE_SHOT)
		return

	# Fallback para cenas que não forem de partícula.
	get_tree().create_timer(0.6).timeout.connect(nova_particula.queue_free, CONNECT_ONE_SHOT)
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
@export_group("Aim line")
@export var aim_line2D: Line2D
@export var drag_line2D: Line2D
@export var velocity_line2D: Line2D
@export var aimLineMultiplier: float = 1

# Aim --------------------------
func Start_Aim() -> void:
	aim_line2D.add_point(Vector2.ZERO)
	aim_line2D.add_point(Vector2.ZERO)

func Draw_Aim() -> void:
	if is_dragging and !is_pointer_inside_piece:
		aim_line2D.visible = true
		
		var initial_point = aim_line2D.to_local(global_position)
		
		var final_point = aim_line2D.to_local(global_position + current_direction * (current_force * aimLineMultiplier))
		
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
	if is_dragging:
		_atualizar_deformacao_arrasto()

	if not is_pointer_inside_piece:
		sprite2D_circulo_limite.visible = true

		# Intensidade baseada na puxada real (com limite máximo em max_distance)
		var porcentagem_forca = clamp(current_distance / max_distance, 0.0, 1.0)
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
var color
var Specular_color
var shake_intensity_target: float = 0.0
var shake_intensity_current: float = 0.0
var shaking: bool = false
var shake_timer: float = 0.0
var shake_amplitude: float = 0.0
var shake_frequency: float = 0.0
var cooldown_timer: float = 0.0
var cooldown_duration: float = 0.1  # Cooldown curto para evitar disparos repetidos
var base_visual_position: Vector2 = Vector2.ZERO
var base_visual_scale: Vector2 = Vector2.ONE
var default_visual_scale: Vector2 = Vector2.ONE

@export var shake_amplitude_min: float = 0.8
@export var shake_amplitude_max: float = 4.0
@export var shake_frequency_min: float = 4.0
@export var shake_frequency_max: float = 32.0

func _atualizar_shake_puxar(intensidade: float) -> void:
	if sprite2D_body == null:
		return

	shake_intensity_target = clamp(intensidade, 0.0, 1.0)
	shake_intensity_current = move_toward(shake_intensity_current, shake_intensity_target, 0.2)

	shake_amplitude = lerpf(shake_amplitude_min, shake_amplitude_max, shake_intensity_current)
	shake_frequency = lerpf(shake_frequency_min, shake_frequency_max, shake_intensity_current)
	shaking = true
	
func parar_shake() -> void:
	shaking = false
	shake_timer = 0.0
	shake_intensity_target = 0.0
	shake_intensity_current = 0.0
	if sprite2D_body != null:
		sprite2D_body.position = base_visual_position
		sprite2D_body.rotation = base_visual_rotation

func _atualizar_deformacao_arrasto() -> void:
	if sprite2D_body == null:
		return

	if not is_dragging or not canPlay or disabled:
		return

	var intensidade = clamp(current_distance / max_distance, 0.0, 1.0)
	var alonga = 1.0 + (intensidade * 0.18)
	var comprime = 1.0 - (intensidade * 0.12)
	var direcao_arrasto := posicao_final_toque_Tela - posicao_inicial_toque_Tela
	if direcao_arrasto.length_squared() > 0.0001:
		var angulo_arrasto := direcao_arrasto.angle()
		sprite2D_body.rotation = base_visual_rotation + angulo_arrasto + deg_to_rad(drag_rotation_offset_degrees)

	if deform_tween and deform_tween.is_valid():
		deform_tween.kill()

	sprite2D_body.scale = Vector2(
		base_visual_scale.x * alonga,
		base_visual_scale.y * comprime
	)

func _retomar_formato_normal() -> void:
	if sprite2D_body == null:
		return

	if deform_tween and deform_tween.is_valid():
		deform_tween.kill()

	deform_tween = create_tween()
	deform_tween.set_trans(Tween.TRANS_ELASTIC)
	deform_tween.set_ease(Tween.EASE_OUT)
	deform_tween.tween_property(sprite2D_body, "scale", base_visual_scale, 0.25)
	deform_tween.parallel().tween_property(sprite2D_body, "rotation", base_visual_rotation, 0.25)
#endregion
func _animar_buff_forca() -> void:
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
		
	if is_instance_valid(sprite2D_body):
		sprite2D_body.self_modulate = team.cor
		
	if playerInfo_atual.level_force >= playerInfo_atual.level_force_strong:
		buff_tween = create_tween().set_loops()
		var cor_brilho = team.cor.lerp(Color.WHITE, 0.8)
		buff_tween.tween_property(sprite2D_body, "self_modulate", cor_brilho, 0.3).set_trans(Tween.TRANS_SINE)
		buff_tween.tween_property(sprite2D_body, "self_modulate", team.cor, 0.3).set_trans(Tween.TRANS_SINE)
func is_frozen() -> bool:
	if playerInfo_atual:
		return playerInfo_atual.disabilitado or playerInfo_atual.turnos_congelamento_armazenado > 0
	return false
# Inicia um piscar contínuo na cor do efeito
func adicionar_efeito_visual(tipo: int, cor: Color) -> void:
	efeitos_visuais_ativos[tipo] = cor
	atualizar_piscar_multi()

func remover_efeito_visual(tipo: int) -> void:
	efeitos_visuais_ativos.erase(tipo)
	atualizar_piscar_multi()

func limpar_todos_efeitos_visuais() -> void:
	efeitos_visuais_ativos.clear()
	atualizar_piscar_multi()

func atualizar_piscar_multi() -> void:
	# Mata o tween antigo
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
		buff_tween = null
	
	# Se não tem nenhum efeito ativo, volta à cor normal
	if efeitos_visuais_ativos.is_empty():
		if is_instance_valid(sprite2D_body):
			sprite2D_body.self_modulate = team.cor
		return
	
	# Pega todas as cores ativas
	var cores: Array[Color] = []
	for cor in efeitos_visuais_ativos.values():
		cores.append(cor)
	
	# Cria um tween que cicla entre todas as cores + volta ao normal
	var tw = create_tween().set_loops()
	for cor in cores:
		tw.tween_property(sprite2D_body, "self_modulate", cor, 0.15)
		tw.tween_property(sprite2D_body, "self_modulate", team.cor, 0.15)
	buff_tween = tw
func animar_efeito_por_carta(card: CardResource) -> void:
	match card.tipo_efeito:
		CardResource.TipoEfeito.FORCA:
			adicionar_efeito_visual(card.tipo_efeito, Color(1.0, 0.5, 0.2))
		CardResource.TipoEfeito.PA:
			adicionar_efeito_visual(card.tipo_efeito, Color(0.3, 0.6, 1.0))
		CardResource.TipoEfeito.Congelamento:
			adicionar_efeito_visual(card.tipo_efeito, Color(0.5, 0.8, 1.0))
		CardResource.TipoEfeito.TrocaLugar:
			adicionar_efeito_visual(card.tipo_efeito, Color(0.7, 0.3, 1.0))
		CardResource.TipoEfeito.Grande:
			adicionar_efeito_visual(card.tipo_efeito, Color(0.3, 1.0, 0.5))
		CardResource.TipoEfeito.Pequeno:
			adicionar_efeito_visual(card.tipo_efeito, Color(1.0, 0.9, 0.3))
		CardResource.TipoEfeito.Empurrão:
			adicionar_efeito_visual(card.tipo_efeito, Color(1.0, 0.7, 0.1))
		CardResource.TipoEfeito.Atrasao:
			adicionar_efeito_visual(card.tipo_efeito, Color(0.6, 0.4, 0.9))
func aplicar_empurrao(velocidade_aliado: Vector2) -> void:
	var impulso = velocidade_aliado * 4
	Set_Current_Velocity(current_velocity + impulso)
	
	if buff_tween and buff_tween.is_valid():
		buff_tween.kill()
	var tw = create_tween().set_parallel(true)
	tw.tween_property(sprite2D_body, "self_modulate", Color.YELLOW, 0.3)
	tw.tween_property(sprite2D_body, "self_modulate", team.cor, 0.3)
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
	menu_radial.fechar()
func aplicar_congelamento(turnos: int) -> void:
	print("Peça congelada por ", turnos, " turnos!")
	current_velocity = Vector2.ZERO
	Set_Current_Velocity(Vector2.ZERO)
	if playerInfo_atual:
		playerInfo_atual.turnos_congelamento_armazenado = turnos
		playerInfo_atual.disabilitado = true
		playerInfo_atual.status_mudou.emit()
	if is_instance_valid(sprite2D_body):
		sprite2D_body.self_modulate = Color(0.5, 0.8, 1.0)
		
func debug_status():
	print("STATUS DEBUG → ", playerInfo.nome)
	print("  Força:", playerInfo_atual.level_force)
	print("  PA:", playerInfo_atual.PA)
	print("  Slots:", playerInfo_atual.slotsUpgrates)
	print("  Buffs Ativos:", playerInfo_atual.duracao_dos_buffs)

func abrir_botoes_cartas():
	var ms = get_tree().root.get_node("MatchScene2d")
	if ms and ms.carta_usada_no_turno:
		print("Já usou carta neste turno, não vai abrir o radial.")
		return
	if PhysicsPlayer2D.last_piece_with_radial != null:
		if PhysicsPlayer2D.last_piece_with_radial != self:
			if PhysicsPlayer2D.last_piece_with_radial.menu_radial.is_open:
				PhysicsPlayer2D.last_piece_with_radial.menu_radial.fechar()
	var cartas = []
	
	for c in playerInfo_atual.slotsUpgrates:
		if c != null:
			if c.is_passiva:
				continue 
			cartas.append(c)
	menu_radial.definir_cartas(cartas, playerInfo_atual.PA)
	if not menu_radial.carta_clicada.is_connected(_on_carta_do_radial):
		menu_radial.carta_clicada.connect(_on_carta_do_radial)
	menu_radial.scale = Vector2(1.5, 1.5)
	menu_radial.abrir()
	PhysicsPlayer2D.last_piece_with_radial = self
#endregion
