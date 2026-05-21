extends PhysicsObject
class_name PhysicsPlayer

@export var debug: bool = true

# Object Proprieties
@export var forca_minima: float = 0.01
@export var forca_maxima: float = 5

# Components
@onready var mira_pivot: Node3D = $MiraPivot
@onready var circulo_limite: MeshInstance3D = $CirculoLimite
@onready var visual_piece: Node3D = $Visual

# Runtime Variables
var direcao_atual: Vector3 = Vector3.ZERO
var forca_atual: float = 0.0
var lerp_forca_atual: float = 0.0
var distancia_atual: float = 0
@export var distancia_maxima: float = 1

var carregando: bool = false
var tempo_inicio_carga: int = 0

var rotacao_base_y: float = 0.0
var spark_cooldowns := {}


var team: Team
@export var playerInfo: TeamPlayer

var canPlay: bool
var disabled: bool = false

@onready var mesh = $Visual/MeshBody

signal clickedPiece(Piece: PhysicsPlayer2D)
signal turnPlayed
var base_rotation_y: float = 0.0

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)

func _ready() -> void:
	mira_pivot.visible = false
	circulo_limite.visible = false
	team = playerInfo.time
	
	effects_ready()
	
	is_pointer_inside_piece = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if visual_piece == null:
		push_error("Não foi possível encontrar o nó Bota02.")
		return
	
	base_visual_position = visual_piece.position
	base_visual_rotation = visual_piece.rotation


func _process(delta: float) -> void:
	if is_dragging:
		effects_process()
		shaking_process(delta)
	
	if debug:
		if is_dragging:
			Draw3d.line(position, position + -direcao_atual * distancia_atual, Color.RED, 0.01)

func _physics_process(delta: float) -> void:
	var ids := spark_cooldowns.keys()
	for id in ids:
		spark_cooldowns[id] -= delta
		if spark_cooldowns[id] <= 0.0:
			spark_cooldowns.erase(id)

#region Input
var is_dragging: bool = false
var is_pointer_inside_piece: bool = false #Mouse/dedo dentro da peça

var posicao_atual_toque_Tela: Vector2 = Vector2.ZERO
var posicao_inicial_toque_Tela: Vector2 = Vector2.ZERO
var posicao_final_toque_Tela: Vector2 = Vector2.ZERO

var posicao_inicial_toque_Mundo3D: Vector3 = Vector3.ZERO
var posicao_final_toque_Mundo3D: Vector3 = Vector3.ZERO

var is_moving: bool

# Atualiza as variaveis de direcao_atual, distancia_atual e forca_atual
func MouseDragging_Update():
	direcao_atual = posicao_inicial_toque_Mundo3D - posicao_final_toque_Mundo3D
	distancia_atual = direcao_atual.length()
	
	direcao_atual = direcao_atual.normalized()
	
	if distancia_atual > distancia_maxima:
		distancia_atual = distancia_maxima
	
	lerp_forca_atual = distancia_atual / distancia_maxima
	forca_atual = lerpf(forca_minima, forca_maxima, lerp_forca_atual)
	
	if forca_atual > forca_maxima:
		forca_atual = forca_maxima

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if !canPlay or disabled:
		return
	
	# Evento - clique do mouse esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			
			# Toca o som de clique normal
			SoundMaster.play_sfx(audio_clique)
			
			# Toca tensao e salva a ref
			sfx_tensao_atual = SoundMaster.play_sfx(audio_tensao, 0.8) 
			
			# Emite um sinal que o player foi clicado
			_on_player_pressed(position)
			
			# Zera variaveis
			direcao_atual = Vector3.ZERO
			
			Set_Current_Velocity(Vector3.ZERO)
			forca_atual = 0.0
			
			# Guarda a posição global do player
			posicao_inicial_toque_Mundo3D = global_position
			
			# Guarda a posição global do player transformada em posição de tela
			posicao_inicial_toque_Tela = camera.unproject_position(global_position)

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if !canPlay or disabled:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# emite que a peça foi clicada
		clickedPiece.emit(self)
		
		# pega a posição do mause na tela
		var mouse_pos = get_viewport().get_mouse_position()
		
		# transforma a posição de tela para a posição em mundo real
		posicao_final_toque_Mundo3D = get_world_pos_from_screen_pos(mouse_pos)
		
		MouseDragging_Update()

	var is_mouse_release = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	var is_touch_release = event is InputEventScreenTouch and not event.pressed

	if is_mouse_release or is_touch_release:
		# Se soltou o dedo e ele estava FORA da peça, executa jogada!
		if not is_pointer_inside_piece:
			_executar_acao()
		# Se soltou o dedo EM CIMA da peça, cancela a jogada
		else:
			_cancelar_interacao()

# Função usada quando o jogador desiste da jogada (solta o mouse no centro)
func _cancelar_interacao() -> void:
	if is_instance_valid(sfx_tensao_atual):
		sfx_tensao_atual.stop()
		
	SoundMaster.play_sfx(audio_cancelar)
	_cancelar_interacao_silenciosa()

func _cancelar_interacao_silenciosa() -> void:
	_on_player_released(position)
	is_dragging = false

	carregando = false
	mira_pivot.visible = false
	circulo_limite.visible = false

func _on_mouse_entered() -> void:
	is_pointer_inside_piece = true

func _on_mouse_exited() -> void:
	is_pointer_inside_piece = false

func _on_player_pressed(pos: Vector3):
	zoom_out_signal.emit(pos)

func _on_player_released(pos: Vector3):
	zoom_in_signal.emit(pos)

func puxar_no_timeout():
	if not is_dragging:
		return

	if direcao_atual.length() > 5.0:
		Shaking_Stop()
		_executar_acao()
	else:
		Shaking_Stop()
		_cancelar_interacao()
		turnPlayed.emit()
#endregion

#region Movement
func _executar_acao() -> void:
	Set_Current_Velocity(direcao_atual * forca_atual)
	
	Shaking_Stop()
	parar_fumaça()
	
	if debug:
		Draw3d.line(position, position + direcao_atual, Color.BLACK, 5)

	# Para o som da tensão esticando
	if is_instance_valid(sfx_tensao_atual): 
		sfx_tensao_atual.stop()
	
	# Decide qual som tocar baseado na força e varia o pitch
	var audio_tiro = audio_chute_normal
	
	if current_velocity.length() >= forca_maxima: # >= e não só >
		audio_tiro = audio_chute_max
		
	SoundMaster.play_sfx(audio_tiro, randf_range(0.9, 1.1))

	# Limpa as variáveis sem tocar o som de erro
	_cancelar_interacao()
	turnPlayed.emit()

func Set_Current_Velocity(new_velocity: Vector3) -> void:
	current_velocity = Vector3(new_velocity.x, 0, new_velocity.z)
	

func move_object(_delta: float) -> void:
	var friction_value = lerpf(friction_min, friction_max, friction)
	var new_velocity = current_velocity + (-current_velocity/2 * friction_value);
	
	Set_Current_Velocity(new_velocity)

	if debug:
		Draw3d.line(position, position + current_velocity, Color.BLUE, 0.05)
	
	if abs(current_velocity.x) < 0.1 && abs(current_velocity.z) < 0.1:
		Set_Current_Velocity(Vector3.ZERO)
		is_moving = false
	else:
		is_moving = true
		
	if !is_moving:
		return
	
	last_position = position
	var newPos = position + (current_velocity * _delta)
	position = newPos

#endregion

#region collisions
var last_PhysicObject_collided: PhysicsObject
var last_PhysicObject_collision_position: Vector3

func Set_Last_PhysicObject_Collision(collision_position: Vector3, object_collided: PhysicsObject) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	
	print("last PhysicObject collided = ", last_PhysicObject_collided.name)
	print("collision position = ", last_PhysicObject_collision_position)
#endregion

#region Others
func effects_process() -> void:
	# Mouse não esta em cima de uma peça
	if is_pointer_inside_piece:
		# Se voltar a mira pro centro, para o som de tensão
		if is_instance_valid(sfx_tensao_atual):
			sfx_tensao_atual.stop()
			
		mira_pivot.visible = false
		circulo_limite.visible = false
		Shaking_Stop()
		smoke_threshold_reached = false
		
	# Mouse não esta em cima de uma peça
	else:
		_desenhar_mira()
		circulo_limite.visible = true

		#Checa se o som existe e altera o pitch baseado na força (de 0.8x a 1.8x)
		if is_instance_valid(sfx_tensao_atual): 
			if not sfx_tensao_atual.playing:
				sfx_tensao_atual.play()
			sfx_tensao_atual.pitch_scale = lerp(0.8, 1.8, lerp_forca_atual)
		
		material_circulo.albedo_color.a = lerp(0.1, 0.6, lerp_forca_atual)
		if lerp_forca_atual >= 1.0:
			material_circulo.albedo_color = Color(1.0, 0.2, 0.2, 0.8)
		else:
			material_circulo.albedo_color = Color(1.0, 1.0, 1.0, lerp(0.1, 0.6, lerp_forca_atual))
		
		var vetor_arrasto_2d = Vector2(direcao_atual.x, direcao_atual.z)
		atualizar_fumaça_limite(lerp_forca_atual, vetor_arrasto_2d)
		
		Shaking_Update(lerp_forca_atual)

func effects_ready() -> void:
	Shaking_Stop()
	material = ShaderMaterial.new()
	outline_material = ShaderMaterial.new()
	mesh.material_override = material
	outline_material.shader = load("res://shaders/outline.gdshader") as Shader
	material.shader = load("res://shaders/NewShaderPlayer.gdshader") as Shader
	aplicar_gradiente_no_material()
	material.next_pass = outline_material
	
	material_circulo = StandardMaterial3D.new()
	material_circulo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_circulo.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	circulo_limite.set_surface_override_material(0, material_circulo)

func set_piece_available(pode_mexer: bool) -> void:
	if material == null:
		return
	if team.id == 1:
		material.set_shader_parameter("saturation", 0.958 if pode_mexer else 0.4)
		material.set_shader_parameter("light_max",  0.97 if pode_mexer else 1.0)
	else:
		material.set_shader_parameter("saturation", 0.958 if pode_mexer else 0.2)
		material.set_shader_parameter("light_max",  0.97 if pode_mexer else 1.0)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var total := state.get_contact_count()
	if total <= 0:
		return

	for i in range(total):
		var collider := state.get_contact_collider_object(i)
		if collider == null:
			continue

		if collider.name.to_lower() == "pitch":
			continue

		var collider_id := collider.get_instance_id()
		if spark_cooldowns.has(collider_id) and spark_cooldowns[collider_id] > 0.0:
			continue
		
		#Som
		if collider is PhysicsPlayer:
			if collider.spark_cooldowns.has(get_instance_id()) and collider.spark_cooldowns[get_instance_id()] > 0.0:
				continue # Ele acordou e já tocou, então eu fico quieto.

		#(Velocidade Relativa)
		# Calcula exatamente o quão rápido um bateu de frente com o outro, ignorando o peso
		var minha_vel = state.get_contact_local_velocity_at_position(i)
		var vel_outro = state.get_contact_collider_velocity_at_position(i)
		var forca_impacto = (minha_vel - vel_outro).length()

		# Ignora esbarrões lentos. Como agora é velocidade pura, .5 ou 1.0 é um bom limite
		if forca_impacto > 0.2: 
			var audio_escolhido: AudioStream = null
			
			if collider is PhysicsPlayer:
				audio_escolhido = audio_impacto_peca
			elif collider is Ball or collider.is_in_group("Balls"):
				audio_escolhido = audio_impacto_bola
			elif collider is Goal or collider.is_in_group("GoleiraHitSom"):
				audio_escolhido = audio_impacto_trave
			else:
				audio_escolhido = audio_impacto_parede
				
			if audio_escolhido != null:
				# Matemática do Volume baseada na Velocidade.
				var forca_relativa = clamp(forca_impacto / 5.0, 0.0, 1.0) 
				var volume_dinamico = lerp(-5.0, 2.0, forca_relativa)
				
				var pitch_dinamico = randf_range(0.85, 1.15)
				SoundMaster.play_sfx(audio_escolhido, pitch_dinamico, volume_dinamico)

		var ponto_global := state.get_contact_collider_position(i)
		ativar_spark_no_ponto_global(ponto_global)

		spark_cooldowns[collider_id] = 0.2
		break
#endregion

#region Utils

# Projeta um raio a partir de uma posição de tela enviada por parâmetro:
#  - se colidiu com algum objeto, retorna a posição da colisão
#  - se não colidiu com nenhum objeto, retorna Vetor 3d de zeros
func get_world_pos_from_screen_pos(screen_position: Vector2) -> Vector3:
	# 1. Project ray from camera to 3D world
	var ray_from = get_viewport().get_camera_3d().project_ray_origin(screen_position)
	var ray_to = ray_from + get_viewport().get_camera_3d().project_ray_normal(screen_position) * 1000.0 # 1000m distance
	
	# 2. Perform physics query
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to, pow(2, 3 - 1))
	var result = space_state.intersect_ray(query)
	
	# 3. Get 3D position
	if result:
		return result.position
	else:
		return Vector3.ZERO

#endregion

#region Sounds
#Variáveis de sons
@export_group("Sons de Interação")
@export var audio_clique: AudioStream
@export var audio_tensao: AudioStream
@export var audio_chute_normal: AudioStream
@export var audio_chute_max: AudioStream
@export var audio_cancelar: AudioStream

# Variável para rastrear o som contínuo da puxada
var sfx_tensao_atual: AudioStreamPlayer
@export_group("Sons de Colisão")
@export var audio_impacto_peca: AudioStream
@export var audio_impacto_bola: AudioStream
@export var audio_impacto_parede: AudioStream
@export var audio_impacto_trave: AudioStream
#endregion

#region Shaders
var fresnel_color 
var material_circulo: StandardMaterial3D
var material: ShaderMaterial
var outline_material: ShaderMaterial
var specular_strength
var fresnel_strength

func aplicar_gradiente_no_material() -> void:
	if material == null :
		return
	if team.id == 2:
		
		var grad_tex := GradientTexture1D.new()
		grad_tex.gradient = gradientV
		var band_count: int = 7
		var light_min: float = 0.005
		var light_max: float = 0.97
		material.set_shader_parameter("diffuse_curve", grad_tex)
		material.set_shader_parameter("band_count", band_count)
		material.set_shader_parameter("light_min", light_min)
		material.set_shader_parameter("light_max", light_max)
		material.set_shader_parameter("enable specular", false)
		material.set_shader_parameter("saturation", 0.958)
	else:
		var grad_tex := GradientTexture1D.new()
		grad_tex.gradient = gradientAz
		var band_count: int = 4
		var light_min: float = 0.005
		var light_max: float = 0.97
		material.set_shader_parameter("diffuse_curve", grad_tex)
		material.set_shader_parameter("band_count", band_count)
		material.set_shader_parameter("light_min", light_min)
		material.set_shader_parameter("light_max", light_max)
		material.set_shader_parameter("enable specular", false)
		material.set_shader_parameter("saturation", 0.958)

func atualizar_gradiente() -> void:
	aplicar_gradiente_no_material()

func trocar_shader(path: String) -> void:
	var shader := load(path) as Shader
	material.shader = shader
	aplicar_gradiente_no_material()
#endregion

#region Shake Effect
# Shake visual
@export var gradientV: Gradient = preload("res://Componentes/PlayerGradientes/GradienteVermelho.tres")
@export var gradientAz: Gradient = preload("res://Componentes/PlayerGradientes/GradienteAzul.tres")

@export var shake_amplitude_min: float = 0.001
@export var shake_amplitude_max: float = 0.01

@export var shake_frequency_min: float = 1
@export var shake_frequency_max: float = 30.0

@export var shake_duration_min: float = 0.05
@export var shake_duration_max: float = 0.12

@export var shake_update_interval: float = 0.3

# Shake state
var shake_update_timer: float = 0.0
var color
var Specular_color
#var shake_intensity_target: float = 0.0
#var shake_intensity_current: float = 0.0
var shaking: bool = false
var shake_timer: float = 0.0
var shake_duration: float = 0.0
var shake_amplitude: float = 0.0
var shake_frequency: float = 0.0
var cooldown_timer: float = 0.0
var cooldown_duration: float = 0.1  # Cooldown curto para evitar disparos repetidos
var base_visual_position: Vector3 = Vector3.ZERO
var base_visual_rotation: Vector3 = Vector3.ZERO

# Faz a movimentação da peça se 'shaking' estiver ativo
func shaking_process(delta: float) -> void:
	if shaking and visual_piece != null:
		shake_timer += delta

		var t := shake_timer * shake_frequency

		var offset := Vector3(
			sin(t * 1.7) * shake_amplitude,
			sin(t * 2.3) * shake_amplitude * 0.5,
			cos(t * 1.9) * shake_amplitude
		)

		visual_piece.position = base_visual_position + offset
		visual_piece.rotation = base_visual_rotation + Vector3(
			sin(t * 2.0) * shake_amplitude * 1.5,
			cos(t * 1.5) * shake_amplitude * 1.5,
			sin(t * 2.8) * shake_amplitude * 1.5
		)

#-A-
func Shaking_Stop() -> void:
	shaking = false
	shake_timer = 0.0
	if visual_piece != null:
		visual_piece.position = base_visual_position
		visual_piece.rotation = base_visual_rotation

func Shaking_Update(intensidade: float) -> void:
	if visual_piece == null:
		return

	shake_update_timer += get_process_delta_time()

	if shake_update_timer < shake_update_interval:
		return

	shake_update_timer = 0.0

	if not shaking:
		shake_timer = 0.0
		shake_duration = lerpf(shake_duration_min, shake_duration_max, intensidade)

	shake_amplitude = lerpf(shake_amplitude_min, shake_amplitude_max, intensidade)
	shake_frequency = lerpf(shake_frequency_min, shake_frequency_max, intensidade)
	
	shaking = true

#endregion

#region Smoke Effect
var smoke_scene: PackedScene = preload("res://shaders/Smoke/Smoke.tscn")
var spark_scene: PackedScene = preload("res://spark.tscn")
var spark_particule: GPUParticles3D
var smoke_particles: GPUParticles3D

@export var smoke_rotation_offset_deg: float = 0.0
@export var smoke_cooldown: float = 1.0  # Cooldown in seconds to prevent spam
@export var smoke_offset_distance: float = 1.0  # Distance from center to spawn smoke

var last_smoke_time: float = 0.0  # For smoke cooldown
var smoke_threshold_reached: bool = false  # To ensure one spawn per threshold
var smoke_instance_atual: Node3D = null

func atualizar_fumaça_limite(porcentagem_forca: float, vetor_arrasto_2d: Vector2) -> void:
	if porcentagem_forca >= 1.0:
		if smoke_instance_atual == null:
			spawn_smoke_limite(vetor_arrasto_2d)

	else:
		parar_fumaça()
		
func spawn_smoke_limite(vetor_arrasto_2d: Vector2) -> void:
	if smoke_scene == null:
		return

	var direcao_arrasto := vetor_arrasto_2d.normalized()
	if direcao_arrasto == Vector2.ZERO:
		return

	var direcao_local := Vector3(direcao_arrasto.x, 0, direcao_arrasto.y).normalized()
	var direcao_oposta_local := -direcao_local

	smoke_instance_atual = smoke_scene.instantiate() as Node3D
	if smoke_instance_atual == null:
		return

	mira_pivot.add_child(smoke_instance_atual)

	# usa a rotação inicial da peça, não a rotação física atual
	var basis_base := Basis(Vector3.UP, base_rotation_y)
	var offset_local := direcao_oposta_local * smoke_offset_distance * 0.2
	var posicao_spawn := global_position + (basis_base * offset_local)
	smoke_instance_atual.global_position = posicao_spawn

	var look_dir := basis_base * direcao_oposta_local
	smoke_instance_atual.look_at(smoke_instance_atual.global_position + look_dir.normalized(), Vector3.UP)

	if smoke_rotation_offset_deg != 0.0:
		smoke_instance_atual.rotate_y(deg_to_rad(smoke_rotation_offset_deg))

	var particles := smoke_instance_atual.get_node_or_null("VFX_Smoke") as GPUParticles3D
	if particles:
		
		particles.emitting = true

func parar_fumaça() -> void:
	if smoke_instance_atual == null:
		return

	var particles := smoke_instance_atual.get_node_or_null("VFX_Smoke") as GPUParticles3D
	if particles:
		particles.emitting = false

	smoke_instance_atual.queue_free()
	smoke_instance_atual = null

func ativar_spark_no_ponto_global(ponto_global: Vector3) -> void:
	if spark_scene == null:
		return

	var spark_instance := spark_scene.instantiate() as Node3D
	if spark_instance == null:
		return

	get_tree().current_scene.add_child(spark_instance)
	spark_instance.global_position = ponto_global
#endregion

#region Aim
func _desenhar_mira() -> void:
	if forca_atual >= forca_minima:
		mira_pivot.visible = true
		var ponto_alvo = global_position + direcao_atual
		mira_pivot.look_at(ponto_alvo, Vector3.UP)

		mira_pivot.scale.z = forca_atual
	else:
		mira_pivot.visible = false
		
#endregion
