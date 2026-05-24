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

@export var gradientV: Gradient = preload("res://Componentes/PlayerGradientes/GradienteVermelho.tres")
@export var gradientAz: Gradient = preload("res://Componentes/PlayerGradientes/GradienteAzul.tres")
@export var shake_amplitude_min: float = 0.001
@export var shake_amplitude_max: float = 0.01
@export var shake_frequency_min: float = 1
@export var shake_frequency_max: float = 30.0
@export var shake_duration_min: float = 0.05
@export var shake_duration_max: float = 0.12
@export_group("Tamanhos do Círculo Limite")
@export var escala_circulo_fraco: float = 0.8
@export var escala_circulo_normal: float = 1.0
@export var escala_circulo_forte: float = 1.4
@export var painel_cartas: Control = null
@export var limite_forca_fraca: int = 15  # Abaixo disso = FRACO
@export var limite_forca_forte: int = 30  # Acima disso = FORTE
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
var input_bloqueado: bool = false
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
@export var escala_base_circulo: float = 1.0
@export var multiplicador_tamanho_por_forca: float = 0.02
@export var smoke_rotation_offset_deg: float = 0.0
@export var smoke_cooldown: float = 1.0  # Cooldown in seconds to prevent spam
@export var smoke_offset_distance: float = 1.0  # Distance from center to spawn smoke
var spark_cooldowns := {}
var last_smoke_time: float = 0.0  # For smoke cooldown
var smoke_threshold_reached: bool = false  # To ensure one spawn per threshold
var smoke_instance_atual: Node3D = null

var team: Team
var playerInfo: TeamPlayer
var status_atual: TeamPlayer
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
@export var gerenciador_cartas: Control

signal zoom_out_signal(pos)
signal zoom_in_signal(pos)

func _ready() -> void:
	mira_pivot.visible = false
	circulo_limite.visible = false
	max_contacts_reported = 1
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

func loadPlayerInfo(plInfo):
	status_atual = plInfo.duplicate(true)
	status_atual.status_mudou.connect(atualizar_fisica_por_status)
	status_atual.status_mudou.connect(atualizar_peca_pelo_status)
	atualizar_peca_pelo_status()
	atualizar_fisica_por_status()

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

func definir_estado_visual(ativo: bool) -> void:
	self.canPlay = ativo
	
	var material_alvo = team.materialAtivo if ativo else team.materialInativo
	
	if material_alvo:
		mesh.material_override = material_alvo.duplicate()

func _physics_process(delta: float) -> void:
	if status_atual.atrai_bola_ativo == true:
		var balls = get_tree().get_nodes_in_group("Balls")
		for ball in balls:
			if not ball is RigidBody3D:
				continue
			var distancia = (ball.global_position - self.global_position).length()
			var raio_circulo = circulo_limite.scale.x 
			if distancia >= 0.4:

				if distancia <= raio_circulo and distancia > 0:
					var dir = (self.global_position - ball.global_position).normalized()
					var dist_norm = clamp(1.0 - (distancia / raio_circulo), 0.0, 1.0)
					var intensidade = dist_norm * status_atual.atrai_bola_forca
					ball.apply_central_force(dir * intensidade)
	var ids := spark_cooldowns.keys()
	for id in ids:
		spark_cooldowns[id] -= delta
		if spark_cooldowns[id] <= 0.0:
			spark_cooldowns.erase(id)

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var player_que_quer_trocar = get_player_que_quer_trocar()
		if player_que_quer_trocar:
			player_que_quer_trocar.status_atual.troca_posicao_ativa = false
			var temp = global_transform.origin
			global_transform.origin = player_que_quer_trocar.global_transform.origin
			player_que_quer_trocar.global_transform.origin = temp
			return
	if is_frozen():
		return
		
	if !canPlay or disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			
			print("Peça clicada! Força atual: ", status_atual.forca)
			clickedPiece.emit(self)
			abrir_botoes_cartas()    # &lt;<&lt; ADICIONADO
			is_dragging = true
			SoundMaster.play_sfx(audio_clique) #Toca o som de clique normal
			sfx_tensao_atual = SoundMaster.play_sfx(audio_tensao, 0.8) #Toca tensao e salva a ref
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
		#Checa se o som existe e altera o pitch baseado na força (de 0.8x a 1.8x)
		if is_instance_valid(sfx_tensao_atual): 
			if not sfx_tensao_atual.playing:
				sfx_tensao_atual.play()
			sfx_tensao_atual.pitch_scale = lerp(0.8, 1.8, porcentagem_forca)
		
		material_circulo.albedo_color.a = lerp(0.1, 0.6, porcentagem_forca)
		if porcentagem_forca >= 1.0:
			material_circulo.albedo_color = Color(1.0, 0.2, 0.2, 0.8)
		else:
			material_circulo.albedo_color = Color(1.0, 1.0, 1.0, lerp(0.1, 0.6, porcentagem_forca))

		atualizar_fumaça_limite(porcentagem_forca, vetor_arrasto_2d)
		
		_atualizar_shake_puxar(porcentagem_forca)
	else:
		# Se voltar a mira pro centro, para o som de tensão
		if is_instance_valid(sfx_tensao_atual):
			sfx_tensao_atual.stop()
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
	var multiplicador_forca = status_atual.forca / 50
	parar_shake()
	parar_fumaça()
	_aplicar_forca(vetor_arrasto_2d )
	
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
	if not carregando_modo3: return
	var vetor_arrasto_2d = posicao_inicial_toque - posicao_atual
	if vetor_arrasto_2d.length_squared() > 25.0:
		direcao_atual_modo3 = vetor_arrasto_2d
	var distancia = posicao_inicial_toque.distance_to(posicao_atual)
	if distancia > raio_saida_pixels:
		if direcao_atual_modo3 != Vector2.ZERO:
			var multiplicador_status: float = 1.0 + (float(status_atual.forca) / 50.0)
			var direcao_3d = Vector3(direcao_atual_modo3.x, 0, direcao_atual_modo3.y).normalized()
			var vetor_forca_3d = direcao_3d * forca_carga_atual * multiplicador_status * mass
			apply_central_impulse(vetor_forca_3d)
			turnPlayed.emit()
		parar_shake()
		_cancelar_interacao()
		
func _desenhar_mira(vetor_2d: Vector2) -> void:
	var multiplicador_status: float = 1.0 + (float(status_atual.forca) / 50.0)
	
	# A mira cresce acompanhando o bônus e a massa
	var vetor_direcao_3d = Vector3(vetor_2d.x, 0, vetor_2d.y) * forca_multiplicador * multiplicador_status * mass
	var forca_visual = vetor_direcao_3d.length()
	
	if forca_visual > 0.1:
		mira_pivot.visible = true
		mira_pivot.look_at(global_position + vetor_direcao_3d, Vector3.UP)
		var limite_max_atual = forca_maxima * multiplicador_status * mass
		mira_pivot.scale.z = remap(clampf(forca_visual, 0.1, limite_max_atual), 0.1, limite_max_atual, 0.1, tamanho_maximo_linha)
	else:
		mira_pivot.visible = false

func _aplicar_forca(vetor_2d: Vector2) -> void:
	if is_frozen():
		return
	if is_instance_valid(sfx_tensao_atual): sfx_tensao_atual.stop()
	
	var multiplicador_status: float = 1.0 + (float(status_atual.forca) / 50.0)
	
	var vetor_forca_3d = Vector3(vetor_2d.x, 0, vetor_2d.y) * forca_multiplicador * multiplicador_status
	var limite_max_atual = forca_maxima * multiplicador_status
	
	var audio_tiro = audio_chute_normal
	# --- INÍCIO DO RAIO-X DO ARREMESSO ---
	print("\n--- RAIO-X DO CHUTE ---")
	print("Força Base da Peça: ", status_atual.forca)
	print("Massa Atual: ", mass, " kg")
	print("Vetor do Mouse (Arrasto): ", vetor_2d.length())
	
	var impulso_final = (vetor_forca_3d * mass).length()
	print("-> IMPULSO FINAL APLICADO: ", impulso_final)
	print("-----------------------\n")
	# --- FIM DO RAIO-X ---
	if vetor_forca_3d.length() >= limite_max_atual: 
		audio_tiro = audio_chute_max
		
	SoundMaster.play_sfx(audio_tiro, randf_range(0.9, 1.1))
	if vetor_forca_3d.length() > limite_max_atual:
		vetor_forca_3d = vetor_forca_3d.normalized() * limite_max_atual
	apply_central_impulse(vetor_forca_3d * mass)
	
	_cancelar_interacao_silenciosa() 
	turnPlayed.emit()

# Função usada quando o jogador desiste da jogada (solta o mouse no centro)
func _cancelar_interacao() -> void:
	if is_instance_valid(sfx_tensao_atual):
		sfx_tensao_atual.stop()
		
	SoundMaster.play_sfx(audio_cancelar)
	_cancelar_interacao_silenciosa()

func parar_shake() -> void:
	shaking = false
	shake_timer = 0.0
	if visual_piece != null:
		visual_piece.position = base_visual_position
		visual_piece.rotation = base_visual_rotation

func _cancelar_interacao_silenciosa() -> void:
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

func is_frozen() -> bool:
	#return status_atual.disabilitado or status_atual.turnos_preso > 0
	return false

func get_player_que_quer_trocar() -> Player:
	var players = get_tree().get_nodes_in_group("Players")
	for p in players:
		if p != self and p.status_atual.troca_posicao_ativa and p.canPlay:
			return p
	return null

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
		if status_atual.empurra_aliados_ativo:
			if collider is Player and collider.team == self.team:
				status_atual.empurra_aliados_ativo = false
				var minha_vel = state.get_contact_local_velocity_at_position(i)
				var vel_outro = state.get_contact_collider_velocity_at_position(i)
				var impulso_base = (minha_vel - vel_outro)
				var impulso_final = impulso_base * status_atual.empurra_aliados_multiplicador
				collider.apply_central_impulse(impulso_final)   
		if status_atual.congelamento_ativo:
	
	# só congela peças (Player), ignora bola, parede etc
			if collider is Player:

		# aplica stun no ALVO (não no atacante)
				collider.status_atual.turnos_preso = status_atual.ultima_carta_usada.duracao
				collider.status_atual.disabilitado = true
				collider.status_atual.status_mudou.emit()

		# limpa estado do atacante
				status_atual.congelamento_ativo = false

				print("=== CONGELAMENTO ATIVADO ===")
				print("Alvo:", collider.playerInfo.nome)
				print("Turnos preso:", collider.status_atual.turnos_preso)

		continue  # interrompe processamento desse contato
				


		var collider_id := collider.get_instance_id()
		if spark_cooldowns.has(collider_id) and spark_cooldowns[collider_id] > 0.0:
			continue
		
		#Som
		if collider is Player:
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
			
			if collider is Player:
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
#				print("Batida de forca: ", forca_impacto, " | Arquivo: ", audio_escolhido, " | Volume dB: ", volume_dinamico)
				SoundMaster.play_sfx(audio_escolhido, pitch_dinamico, volume_dinamico)

		var ponto_global := state.get_contact_collider_position(i)
#		print("colidiu com:", collider.name, " em:", ponto_global)

		ativar_spark_no_ponto_global(ponto_global)

		spark_cooldowns[collider_id] = 0.2
		break

func _on_player_pressed(pos: Vector3):
	zoom_out_signal.emit(pos)

func _on_player_released(pos: Vector3):
	zoom_in_signal.emit(pos)

func atualizar_fisica_por_status():
	
	# Aumentar a massa torna a peça mais difícil de ser empurrada por outros
	var massa_base  = 1.0 + (status_atual.forca * 0.05) 
	if status_atual.aumento_de_tamano:
		mass = massa_base * 2.0   # dobra a massa
	else:
		mass = massa_base
	if status_atual.diminui_de_tamano:
		mass = massa_base * 0.5
	else:
		mass = massa_base
	# Se quiser que ela deslize mais ou menos no campo
	physics_material_override.friction = clamp(1.0 - (status_atual.forca * 0.01), 0.1, 1.0)

func atualizar_peca_pelo_status() -> void:
	if not is_instance_valid(status_atual): return
	
	# --- FÍSICA ---

	if status_atual.aumento_de_tamano:
	# aumenta o modelo real
		if visual_piece:
			visual_piece.scale = Vector3(1.5, 1.5, 1.5)
		var colisor = $CollisionShape3D
		if colisor:
			colisor.scale = Vector3(1.5, 1.5, 1.5)	

	if status_atual.diminui_de_tamano:
		if visual_piece:
			visual_piece.scale = Vector3(0.5, 0.5, 0.5)
		var colisor = $CollisionShape3D
		if colisor:
			colisor.scale = Vector3(0.5, 0.5, 0.5)	
	if status_atual.diminui_de_tamano == false and status_atual.aumento_de_tamano== false:
		if visual_piece:
			visual_piece.scale = Vector3(1.0, 1.0, 1.0)
		var colisor = $CollisionShape3D
		if colisor:
			colisor.scale = Vector3(1.0, 1.0, 1.0)
	# --- VISUAL DO CÍRCULO (SISTEMA DE 3 TAMANHOS) ---
	if is_instance_valid(circulo_limite):
		var nova_escala: float = escala_circulo_normal # Começa assumindo o tamanho Normal
		# Verifica em qual 'Degrau' de força o jogador está
		if status_atual.forca < limite_forca_fraca:
			nova_escala = escala_circulo_fraco
		elif status_atual.forca >= limite_forca_forte:
			nova_escala = escala_circulo_forte
		circulo_limite.scale = Vector3(nova_escala, nova_escala, nova_escala)
		
	# Atualiza a mira se estiver arrastando
	if is_dragging:
		_desenhar_mira(vetor_arrasto_atual)

func debug_status():
	print("STATUS DEBUG → ", playerInfo.nome)
	print("  Força:", status_atual.forca)
	print("  PA:", status_atual.PA)
	print("  Slots:", status_atual.slotsUpgrates)
	print("  Buffs Ativos:", status_atual.duracao_dos_buffs)

func abrir_botoes_cartas():
	if painel_cartas == null:
		return
	
	var cam := get_viewport().get_camera_3d()
	var pos_tela := cam.unproject_position(global_transform.origin)
	
	# Ajuste fino da posição na tela
	pos_tela.x += 40
	pos_tela.y -= 20
	
	painel_cartas.position = pos_tela
	painel_cartas.visible = true
	painel_cartas.definir_piece(self)
	painel_cartas.definir_cartas(playerInfo.slotsUpgrates)
