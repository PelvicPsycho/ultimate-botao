extends RigidBody3D

class_name Player

enum ModoTiro { PUXAR, EMPURRAR, CARREGAR }

var modo_atual: ModoTiro = ModoTiro.PUXAR

@export var forca_multiplicador: float = 0.21
@export var forca_maxima: float = 30.0
@export var raio_saida_pixels: float = 40.0  # Define a borda da peça na tela
@export var multiplicador_comprimento_mira: float = 1.0  #nao parece estar fazendo nada
@export var tamanho_maximo_linha: float = 15.0

# Shake visual
@export var band_count: int = 5
@export var light_min: float = 0.182
@export var light_max: float = 0.975
@export var gradient: Gradient
@export var shake_amplitude_min: float = 0.001
@export var shake_amplitude_max: float = 0.01
@export var shake_frequency_min: float = 1
@export var shake_frequency_max: float = 30.0
@export var shake_duration_min: float = 0.05
@export var shake_duration_max: float = 0.12
var debug: bool = true
# Variáveis Gerais
var is_dragging: bool = false
var is_pointer_inside: bool = false #Mouse/dedo dentro da peça
var posicao_inicial_toque: Vector2 = Vector2.ZERO
var vetor_arrasto_atual: Vector2 = Vector2.ZERO

# Variáveis do Modo Empurrar
var direcao_travada: bool = false
var vetor_direcao_empurrao: Vector2 = Vector2.ZERO
var tempo_trava_direcao: int = 0
var forca_acumulada_empurrao: float = 0.0

# Variáveis do Modo Carregar  (Modo 3)
var carregando_modo3: bool = false
var tempo_inicio_carga: int = 0
var forca_carga_atual: float = 0.0
var direcao_atual_modo3: Vector2 = Vector2.ZERO
var fresnel_color 
@onready var mira_pivot: Node3D = $MiraPivot
@onready var circulo_limite: MeshInstance3D = $CirculoLimite
@onready var visual_piece: Node3D = $Visual
var material_circulo: StandardMaterial3D
var material: ShaderMaterial
var outline_material: ShaderMaterial
var specular_strength
var fresnel_strength
var smoke_scene: PackedScene = preload("res://shaders/Smoke/Smoke.tscn")
var spark_scene: PackedScene = preload("res://spark.tscn")
var spark_particule: GPUParticles3D
var smoke_particles: GPUParticles3D
var rotacao_base_y: float = 0.0
@onready var mesh_instance: MeshInstance3D =$Visual/Botao2
@export var smoke_rotation_offset_deg: float = 0.0
@export var smoke_cooldown: float = 1.0  # Cooldown in seconds to prevent spam
@export var smoke_offset_distance: float = 1.0  # Distance from center to spawn smoke
var spark_cooldowns := {}
var last_smoke_time: float = 0.0  # For smoke cooldown
var smoke_threshold_reached: bool = false  # To ensure one spawn per threshold
var smoke_instance_atual: Node3D = null

var team: Team
@export var playerInfo: TeamPlayer

var canPlay: bool
var disabled: bool = false

@onready var mesh = $Visual/Botao2

signal clickedPiece(Piece: Player)
signal turnPlayed
var base_rotation_y: float = 0.0
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
var base_visual_position: Vector3 = Vector3.ZERO
var base_visual_rotation: Vector3 = Vector3.ZERO

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)

func _ready() -> void:
	mira_pivot.visible = false
	circulo_limite.visible = false


	max_contacts_reported = 1
	team = playerInfo.time
	
	material = ShaderMaterial.new()
	outline_material = ShaderMaterial.new()
	mesh.material_override = material
	outline_material.shader = load("res://shaders/outline.gdshader") as Shader
	material.shader = load("res://shaders/pesaVermelha.gdshader") as Shader
	#if team.id == 1:
		#trocar_shader("res://shaders/pesaVermelha.gdshader")
		#color = Color(0, 0.0, 1, 1)
		#material.set_shader_parameter("color",color)
		#Specular_color = Color(0.28,0.28,0.28,1.77)
		#material.set_shader_parameter("specular_color", Specular_color)
		#fresnel_color = Color(0.51,0.51,0.51,0.77)
		#material.set_shader_parameter("fresnel_color", fresnel_color)
		#specular_strength =0.1
		#material.set_shader_parameter("specular_strength", specular_strength)
		#fresnel_strength = 0.77
		#material.set_shader_parameter("fresnel_strength", fresnel_strength)
	#else:
		#trocar_shader("res://shaders/pesaVermelha.gdshader")
		#var color := Color(1, 0, 0, 1)
		#material.set_shader_parameter("color",color)
		#Specular_color = Color(0.28,0.28,0.28,1.77)
		#material.set_shader_parameter("specular_color", Specular_color)
		#fresnel_color = Color(0.51,0.51,0.51,0.77)
		#material.set_shader_parameter("fresnel_color", fresnel_color)
		#specular_strength =0.1
		#material.set_shader_parameter("specular_strength", specular_strength)
		#fresnel_strength = 0.77
		#material.set_shader_parameter("fresnel_strength", fresnel_strength)

	material.next_pass = outline_material
	
	material_circulo = StandardMaterial3D.new()
	material_circulo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_circulo.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	circulo_limite.set_surface_override_material(0, material_circulo)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if visual_piece == null:
		push_error("Não foi possível encontrar o nó Bota02.")
		return

	base_visual_position = visual_piece.position
	base_visual_rotation = visual_piece.rotation
func aplicar_gradiente_no_material() -> void:
	if material == null or gradient == null:
		return

	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient

	material.set_shader_parameter("diffuse_curve", grad_tex)
	material.set_shader_parameter("band_count", band_count)
	material.set_shader_parameter("light_min", light_min)
	material.set_shader_parameter("light_max", light_max)
	material.set_shader_parameter("enable specular", false)
func atualizar_gradiente() -> void:
	aplicar_gradiente_no_material()
func atualizar_bandas(novo_band_count: int, novo_min: float, novo_max: float) -> void:
	if material == null:
		return

	band_count = novo_band_count
	light_min = novo_min
	light_max = novo_max
	aplicar_gradiente_no_material()

func _process(delta: float) -> void:
	if modo_atual == ModoTiro.CARREGAR and carregando_modo3:
		var tempo_decorrido = Time.get_ticks_msec() - tempo_inicio_carga
		var ciclo_ms = tempo_decorrido % 1000
		var porcentagem_forca = ciclo_ms / 1000.0

		forca_carga_atual = porcentagem_forca * forca_maxima

		if direcao_atual_modo3 != Vector2.ZERO:
			var vetor_mira_pulsante = direcao_atual_modo3.normalized() * (forca_carga_atual / forca_multiplicador)
			_desenhar_mira(vetor_mira_pulsante)

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


func set_piece_available(pode_mexer: bool) -> void:
	if material == null:
		return

	if team.id == 1:
		material.set_shader_parameter("color", Color(0.0, 0.0, 1.0, 1.0) if pode_mexer else Color(0.0, 0.0, 0.35, 1.0))
	else:
		material.set_shader_parameter("color", Color(1.0, 0.0, 0.0, 1.0) if pode_mexer else Color(0.45, 0.0, 0.0, 1.0))

func _physics_process(delta: float) -> void:
	var ids := spark_cooldowns.keys()
	for id in ids:
		spark_cooldowns[id] -= delta
		if spark_cooldowns[id] <= 0.0:
			spark_cooldowns.erase(id)
func trocar_shader(path: String) -> void:
	var shader := load(path) as Shader
	material.shader = shader
	aplicar_gradiente_no_material()
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if !canPlay or disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			_on_player_pressed(position)
			vetor_arrasto_atual = Vector2.ZERO
			posicao_inicial_toque = camera.unproject_position(global_position)

			direcao_travada = false
			forca_acumulada_empurrao = 0.0

			if modo_atual == ModoTiro.CARREGAR:
				carregando_modo3 = true
				tempo_inicio_carga = Time.get_ticks_msec()
				direcao_atual_modo3 = Vector2.ZERO
				forca_carga_atual = 0.0

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if !canPlay or disabled:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		clickedPiece.emit(self)
		
		match modo_atual:
			ModoTiro.PUXAR:
				_atualizar_mira_puxar(event.position)
			ModoTiro.EMPURRAR:
				_processar_empurrao(event.position)
			ModoTiro.CARREGAR:
				_processar_carregar(event.position)

	var is_mouse_release = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	var is_touch_release = event is InputEventScreenTouch and not event.pressed

	if is_mouse_release or is_touch_release:
		match modo_atual:
			ModoTiro.PUXAR:
				if not is_pointer_inside:
					_chutar_peca_puxar(event.position)
				else:
					_cancelar_interacao()

			ModoTiro.EMPURRAR:
				if direcao_travada:
					_executar_tiro_empurrar()
				else:
					_cancelar_interacao()

			ModoTiro.CARREGAR:
				_cancelar_interacao()

func _atualizar_mira_puxar(posicao_atual: Vector2) -> void:
	vetor_arrasto_atual = posicao_inicial_toque - posicao_atual
	
	if not is_pointer_inside:
		var vetor_arrasto_2d = posicao_inicial_toque - posicao_atual
		_desenhar_mira(vetor_arrasto_2d)
		circulo_limite.visible = true
		var vetor_direcao_3d = Vector3(vetor_arrasto_2d.x, 0, vetor_arrasto_2d.y) * forca_multiplicador
		var forca_atual = vetor_direcao_3d.length()
		var porcentagem_forca = clamp(forca_atual / forca_maxima, 0.0, 1.0)
		material_circulo.albedo_color.a = lerp(0.1, 0.6, porcentagem_forca)
		if porcentagem_forca >= 1.0:
			material_circulo.albedo_color = Color(1.0, 0.2, 0.2, 0.8)
		else:
			material_circulo.albedo_color = Color(1.0, 1.0, 1.0, lerp(0.1, 0.6, porcentagem_forca))

		atualizar_fumaça_limite(porcentagem_forca, vetor_arrasto_2d)
		
		_atualizar_shake_puxar(porcentagem_forca)
	else:
		mira_pivot.visible = false
		circulo_limite.visible = false
		parar_shake()
		smoke_threshold_reached = false
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

func _atualizar_shake_puxar(intensidade: float) -> void:
	if visual_piece == null:
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

func _chutar_peca_puxar(posicao_final: Vector2) -> void:
	var vetor_arrasto_2d = posicao_inicial_toque - posicao_final
	parar_shake()
	parar_fumaça()
	_aplicar_forca(vetor_arrasto_2d)

func puxar_no_timeout():
	if not is_dragging:
		return

	if vetor_arrasto_atual.length() > 5.0:
		parar_shake()
		_aplicar_forca(vetor_arrasto_atual)
	else:
		parar_shake()
		_cancelar_interacao()
		turnPlayed.emit()

func _processar_empurrao(posicao_atual: Vector2) -> void:
	if not direcao_travada:
		var distancia = posicao_inicial_toque.distance_to(posicao_atual)

		if distancia > raio_saida_pixels:
			direcao_travada = true
			vetor_direcao_empurrao = (posicao_atual - posicao_inicial_toque).normalized()
			tempo_trava_direcao = Time.get_ticks_msec()
	else:
		var tempo_decorrido = Time.get_ticks_msec() - tempo_trava_direcao

		if tempo_decorrido <= 100:
			var vetor_movimento = posicao_atual - posicao_inicial_toque
			var forca_atual = vetor_movimento.dot(vetor_direcao_empurrao)
			forca_acumulada_empurrao = max(forca_acumulada_empurrao, forca_atual)

			var vetor_mira = vetor_direcao_empurrao * forca_acumulada_empurrao
			_desenhar_mira(vetor_mira)
		else:
			_executar_tiro_empurrar()

func _executar_tiro_empurrar() -> void:
	var vetor_final_2d = vetor_direcao_empurrao * forca_acumulada_empurrao
	_aplicar_forca(vetor_final_2d)

func _processar_carregar(posicao_atual: Vector2) -> void:
	if not carregando_modo3:
		return

	var vetor_arrasto_2d = posicao_inicial_toque - posicao_atual

	if vetor_arrasto_2d.length() > 5.0:
		direcao_atual_modo3 = vetor_arrasto_2d

	var distancia = posicao_inicial_toque.distance_to(posicao_atual)

	if distancia > raio_saida_pixels:
		if direcao_atual_modo3 != Vector2.ZERO:
			var direcao_3d = Vector3(direcao_atual_modo3.x, 0, direcao_atual_modo3.y).normalized()
			var vetor_forca_3d = direcao_3d * forca_carga_atual
			apply_central_impulse(vetor_forca_3d)
			turnPlayed.emit()

		parar_shake()
		_cancelar_interacao()

func _desenhar_mira(vetor_2d: Vector2) -> void:
	var vetor_direcao_3d = Vector3(vetor_2d.x, 0, vetor_2d.y) * forca_multiplicador
	var forca_visual = vetor_direcao_3d.length()

	if forca_visual > 0.1:
		mira_pivot.visible = true
		var ponto_alvo = global_position + vetor_direcao_3d
		mira_pivot.look_at(ponto_alvo, Vector3.UP)

		var forca_travada = clamp(forca_visual, 0.1, forca_maxima)
		mira_pivot.scale.z = remap(forca_travada, 0.1, forca_maxima, 0.1, tamanho_maximo_linha)
	else:
		mira_pivot.visible = false

func _aplicar_forca(vetor_2d: Vector2) -> void:
	var vetor_forca_3d = Vector3(vetor_2d.x, 0, vetor_2d.y) * forca_multiplicador

	if vetor_forca_3d.length() > forca_maxima:
		vetor_forca_3d = vetor_forca_3d.normalized() * forca_maxima

	apply_central_impulse(vetor_forca_3d)
	_cancelar_interacao()
	turnPlayed.emit()

func parar_shake() -> void:
	shaking = false
	shake_timer = 0.0
	if visual_piece != null:
		visual_piece.position = base_visual_position
		visual_piece.rotation = base_visual_rotation

func _cancelar_interacao() -> void:
	_on_player_released(position)
	is_dragging = false
	direcao_travada = false
	carregando_modo3 = false
	mira_pivot.visible = false
	circulo_limite.visible = false

func _on_mouse_entered() -> void:
	is_pointer_inside = true

func _on_mouse_exited() -> void:
	is_pointer_inside = false
func ativar_spark_no_ponto_global(ponto_global: Vector3) -> void:
	if spark_scene == null:
		return

	var spark_instance := spark_scene.instantiate() as Node3D
	if spark_instance == null:
		return

	get_tree().current_scene.add_child(spark_instance)
	spark_instance.global_position = ponto_global

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

		var ponto_global := state.get_contact_collider_position(i)
		print("colidiu com:", collider.name, " em:", ponto_global)

		ativar_spark_no_ponto_global(ponto_global)

		spark_cooldowns[collider_id] = 0.2
		break

func _on_player_pressed(pos: Vector3):
	zoom_out_signal.emit(pos)

func _on_player_released(pos: Vector3):
	zoom_in_signal.emit(pos)
