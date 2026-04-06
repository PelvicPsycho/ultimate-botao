extends RigidBody3D
class_name Player

enum ModoTiro { PUXAR, EMPURRAR, CARREGAR }
var modo_atual: ModoTiro = ModoTiro.PUXAR

@export var forca_multiplicador: float = 0.05
@export var forca_maxima: float = 30.0
@export var raio_saida_pixels: float = 40.0 # Define a borda da peça na tela
@export var multiplicador_comprimento_mira: float = 1.0 #nao parece estar fazendo nada
@export var tamanho_maximo_linha: float = 15.0

# Variáveis Gerais
var is_dragging: bool = false
var is_pointer_inside: bool = false #Mouse/dedo dentro da peça
var posicao_inicial_toque: Vector2 = Vector2.ZERO

# Variáveis do Modo Empurrar
var direcao_travada: bool = false
var vetor_direcao_empurrao: Vector2 = Vector2.ZERO
var tempo_trava_direcao: int = 0
var forca_acumulada_empurrao: float = 0.0

# Variáveis do Modo Carregar (Modo 3)
var carregando_modo3: bool = false
var tempo_inicio_carga: int = 0
var forca_carga_atual: float = 0.0
var direcao_atual_modo3: Vector2 = Vector2.ZERO

@onready var mira_pivot: Node3D = $MiraPivot

#info do time da peça
var team: Team
@export var playerInfo: TeamPlayer
var canPlay: bool
var disabled: bool = false

#material da peça
@onready var mesh = $MeshInstance3D

signal clickedPiece(Piece: Player)
signal turnPlayed

func _ready() -> void:
	mira_pivot.visible = false
	team = playerInfo.time
	var material = StandardMaterial3D.new()
	material.albedo_color = team.cor      
	# Aplicamos o material ao mesh (índice 0 é a primeira superfície)
	$MeshInstance3D.set_surface_override_material(0, material)
	
	# Conecta os sinais de mouse/touch nativos da Godot
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# ==========================================
# LOOP DE TEMPO (Necessário para o Modo 3)
# ==========================================
func _process(_delta: float) -> void:
	if modo_atual == ModoTiro.CARREGAR and carregando_modo3:
		# Pega o tempo em milissegundos desde o clique
		var tempo_decorrido = Time.get_ticks_msec() - tempo_inicio_carga
		
		# O operador '%' (módulo) faz o valor dar a volta. 
		# Ex: 998, 999, 0, 1, 2... Fica sempre entre 0 e 1000 (1 segundo)
		var ciclo_ms = tempo_decorrido % 1000
		
		# Transforma em uma porcentagem de 0.0 a 1.0
		var porcentagem_forca = ciclo_ms / 1000.0
		
		# Calcula a força atual baseada no tempo
		forca_carga_atual = porcentagem_forca * forca_maxima
		
		# Se já tivermos uma direção (se o jogador puxou um pouquinho), desenha a mira pulsando
		if direcao_atual_modo3 != Vector2.ZERO:
			# Para a função de desenhar mira entender, passamos o vetor no formato 2D
			var vetor_mira_pulsante = direcao_atual_modo3.normalized() * (forca_carga_atual / forca_multiplicador)
			_desenhar_mira(vetor_mira_pulsante)

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:

	#se não for da equipe, não interage
	if !canPlay or disabled:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			posicao_inicial_toque = event.position
			
			# Resets específicos
			direcao_travada = false
			forca_acumulada_empurrao = 0.0
			
			# Setup Inicial do Modo 3
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
	
	# TRATA O ARRASTO (Movimento do Mouse ou do Dedo)
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		clickedPiece.emit(self)
		
		match modo_atual:
			ModoTiro.PUXAR:
				_atualizar_mira_puxar(event.position)
			ModoTiro.EMPURRAR:
				_processar_empurrao(event.position)
			ModoTiro.CARREGAR:
				_processar_carregar(event.position)

	# TRATA O SOLTAR (Quando o clique ou o toque na tela acaba)
	var is_mouse_release = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	var is_touch_release = event is InputEventScreenTouch and not event.pressed
	
	if is_mouse_release or is_touch_release:
		match modo_atual:
			ModoTiro.PUXAR:
				# Se soltou o dedo e ele estava FORA da peça, atira!
				if not is_pointer_inside:
					_chutar_peca_puxar(event.position)
				# Se soltou o dedo EM CIMA da peça, cancela a jogada.
				else:
					_cancelar_interacao()

			ModoTiro.EMPURRAR:
				if direcao_travada:
					_executar_tiro_empurrar()
				else:
					_cancelar_interacao()
			ModoTiro.CARREGAR:
				_cancelar_interacao()

# ==========================================
# LÓGICA MODO 1: PUXAR
# ==========================================
func _atualizar_mira_puxar(posicao_atual: Vector2) -> void:
	# Se o ponteiro NÃO estiver dentro da peça, desenha a mira
	if not is_pointer_inside:
		var vetor_arrasto_2d = posicao_inicial_toque - posicao_atual
		_desenhar_mira(vetor_arrasto_2d)
	else:
		# Se o ponteiro estiver em cima da peça, esconde a mira
		mira_pivot.visible = false

func _chutar_peca_puxar(posicao_final: Vector2) -> void:
	var vetor_arrasto_2d = posicao_inicial_toque - posicao_final
	_aplicar_forca(vetor_arrasto_2d)

# ==========================================
# LÓGICA MODO 2: EMPURRAR
# ==========================================
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

# ==========================================
# LÓGICA MODO 3: CARREGAR
# ==========================================
func _processar_carregar(posicao_atual: Vector2) -> void:
	if not carregando_modo3:
		return
		
	# A direção é inversa ao arrasto, igual ao Modo 1
	var vetor_arrasto_2d = posicao_inicial_toque - posicao_atual
	
	# Só define a direção se puxar um pouquinho (evita tremedeira do dedo)
	if vetor_arrasto_2d.length() > 5.0:
		direcao_atual_modo3 = vetor_arrasto_2d
	
	# Checa se o dedo SAIU do raio da peça
	var distancia = posicao_inicial_toque.distance_to(posicao_atual)
	if distancia > raio_saida_pixels:
		# Atirou! Aplica a força exata que estava acumulada no _process
		if direcao_atual_modo3 != Vector2.ZERO:
			# Cria o vetor 3D usando a direção que apontamos e a força calculada no tempo
			var direcao_3d = Vector3(direcao_atual_modo3.x, 0, direcao_atual_modo3.y).normalized()
			var vetor_forca_3d = direcao_3d * forca_carga_atual
			
			apply_central_impulse(vetor_forca_3d)
			
			#espera a fisica ocorrer
			turnPlayed.emit()
			
		_cancelar_interacao()

# ==========================================
# FUNÇÕES UTILITÁRIAS
# ==========================================
func _desenhar_mira(vetor_2d: Vector2) -> void:
	var vetor_direcao_3d = Vector3(vetor_2d.x, 0, vetor_2d.y) * forca_multiplicador
	var forca_visual = vetor_direcao_3d.length()

	if forca_visual > 0.1:
		mira_pivot.visible = true
		var ponto_alvo = global_position + vetor_direcao_3d #Mira aponta p chute
		mira_pivot.look_at(ponto_alvo, Vector3.UP)
		
		# 1. Trava a força física no máximo normal (ex: 30)
		var forca_travada = clamp(forca_visual, 0.1, forca_maxima)
		
		# 2. Converte a escala da física para a escala visual!
		# Lê-se: "Pegue a forca_travada (que vai de 0.1 até forca_maxima) 
		# e transforme isso num valor que vai de 0.1 até tamanho_maximo_linha"
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

func _cancelar_interacao() -> void:
	is_dragging = false
	direcao_travada = false
	carregando_modo3 = false
	mira_pivot.visible = false

func _on_mouse_entered() -> void:
	is_pointer_inside = true

func _on_mouse_exited() -> void:
	is_pointer_inside = false

#func _on_body_entered(body: Node) -> void:
#	pass
	"""
	if body is ball:
		if team == Team.Team1:
			EquipeAtual.current_posse=1
		elif team == Team.Team2:
			EquipeAtual.current_posse=2
	"""
