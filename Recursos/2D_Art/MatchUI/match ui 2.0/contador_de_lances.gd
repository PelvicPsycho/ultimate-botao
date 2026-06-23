extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var texto_lances: Sprite2D
@export var bola : Sprite2D
@export var lance_ponto_1: Sprite2D
@export var lance_ponto_2: Sprite2D
@export var away_team: bool = false
@export var distancia_fora_da_tela: float = 500.0
@export var duracao_tween: float = 0.3


# --- NOVAS VARIÁVEIS PARA O GIRO DA BOLA ---
@export var velocidade_giro_bola: float = 2.0 # Ajuste a velocidade aqui (valores negativos giram para o outro lado)
var girando_bola: bool = false
# -------------------------------------------
var cor_atual_time: Color = Color.WHITE
var nome_animacao: String = "contador anim"
var esperando_entrada: bool = false
var tween_oscilacao_lance1: Tween
var tween_oscilacao_lance2: Tween
var esta_na_tela: bool = false

signal entrada_concluida
signal saida_concluida


func _ready() -> void:
	# Posiciona fora da tela no lado correto
	if away_team:
		position.x = distancia_fora_da_tela
	else:
		position.x = -distancia_fora_da_tela
	
	var meus_sprites = get_children().filter(func(filho): return filho is Sprite2D)
	if away_team:
		for sprite in meus_sprites:
			sprite.flip_h = true
		texto_lances.flip_h = false
		texto_lances.rotation_degrees = 11
		velocidade_giro_bola = velocidade_giro_bola * -1
		nome_animacao = "contador anim reverse"
	
	animation_player.play(nome_animacao)
	await get_tree().process_frame
	await get_tree().process_frame
	animation_player.pause()
	#animation_player.play("so_a_bola")

# --- NOVO _PROCESS PARA O GIRO CONTÍNUO ---
func _process(delta: float) -> void:
	if girando_bola and is_instance_valid(bola):
		# Soma a rotação de forma suave usando o tempo do frame (delta)
		bola.rotation += velocidade_giro_bola * delta
# ------------------------------------------

# Anima a entrada: prepara frame 1 → tween até (0,0) → continua AnimationPlayer → entrada_concluida
func animar_entrada(cor_novo_time: Color) -> void:
	_aplicar_cores(cor_novo_time)
	
	# Toca a animação e pausa no frame seguinte (frame 1)
	animation_player.play(nome_animacao)
	await get_tree().process_frame
	await get_tree().process_frame
	animation_player.pause()
	
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2.ZERO, duracao_tween)
	tween.tween_callback(_play_animacao_entrada)

func _play_animacao_entrada() -> void:
	# Retoma a animação, mas pula o frame 0 com advance
	animation_player.play(nome_animacao)
	animation_player.advance(0.02)
	animation_player.animation_finished.connect(_on_entrada_terminou, CONNECT_ONE_SHOT)

func _on_entrada_terminou(_anim_name: String) -> void:
	esta_na_tela = true
	girando_bola = true
	if lance_ponto_1:
		var tween = create_tween()
		tween.tween_property(lance_ponto_1, "modulate", cor_atual_time, duracao_tween)
		
		# --- OSCILAÇÃO FLUIDA DE PÊNDULO ---
		tween_oscilacao_lance1 = create_tween()
		tween_oscilacao_lance1.set_loops() 
		
		# 1. Sai do meio (rápido) e freia na ponta direita
		tween_oscilacao_lance1.tween_property(lance_ponto_1, "rotation_degrees", 25.0, 1.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
		# 2. Sai da ponta direita (lento), cruza o meio rápido, e freia na ponta esquerda
		tween_oscilacao_lance1.tween_property(lance_ponto_1, "rotation_degrees", -25.0, 2.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
		# 3. Sai da ponta esquerda (lento) e acelera pro meio (chega rápido pra emendar no passo 1)
		tween_oscilacao_lance1.tween_property(lance_ponto_1, "rotation_degrees", 0.0, 1.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
	entrada_concluida.emit()

# Anima a saída: AnimationPlayer reverso → tween para fora → saida_concluida
# Anima a saída: AnimationPlayer reverso → tween para fora → saida_concluida
func animar_saida() -> void:
	if not esta_na_tela:
		saida_concluida.emit()
		return
	
	girando_bola = false # DESLIGA O GIRO CONTÍNUO IMEDIATAMENTE
	
	# --- PARA AS OSCILAÇÕES ANTES DE SAIR DA TELA ---
	if tween_oscilacao_lance1 and tween_oscilacao_lance1.is_valid():
		tween_oscilacao_lance1.kill()
	if tween_oscilacao_lance2 and tween_oscilacao_lance2.is_valid():
		tween_oscilacao_lance2.kill()
		
	# Devolve ambos para o eixo 0 imediatamente, para saírem retos
	if lance_ponto_1:
		lance_ponto_1.rotation_degrees = 0.0
	if lance_ponto_2:
		lance_ponto_2.rotation_degrees = 0.0
	# ------------------------------------------------
	
	# O Godot usa radianos. TAU equivale a 360 graus (2 * PI).
	bola.rotation = wrapf(bola.rotation, 0.0, TAU)
	
	animation_player.play_backwards(nome_animacao)
	animation_player.animation_finished.connect(_on_animacao_saida_terminou, CONNECT_ONE_SHOT)

func _on_animacao_saida_terminou(_anim_name: String) -> void:
	var destino_x = distancia_fora_da_tela if away_team else -distancia_fora_da_tela
	var tween = create_tween()
	tween.tween_property(self, "position:x", destino_x, duracao_tween)
	tween.tween_callback(_on_saida_terminou)

func _on_saida_terminou() -> void:
	if lance_ponto_1:
		lance_ponto_1.modulate = Color.WHITE
	if lance_ponto_2:
		lance_ponto_2.modulate = Color.WHITE
	esta_na_tela = false
	saida_concluida.emit()

func _aplicar_cores(cor: Color) -> void:
	$ContadorDeLanceCor.modulate = cor
	$Bola.modulate = cor

# Chame essa função externamente quando o segundo lance for ativado
func animar_segundo_lance(qual_time: bool) -> void:
	# 1. Para a oscilação eterna do primeiro lance
	if tween_oscilacao_lance1 and tween_oscilacao_lance1.is_valid():
		tween_oscilacao_lance1.kill()
		
	# 2. Devolve o primeiro lance para o eixo 0 suavemente
	if lance_ponto_1:
		var reset_tween = create_tween()
		reset_tween.tween_property(lance_ponto_1, "rotation_degrees", 0.0, 0.2)

	# 3. Pinta e inicia a oscilação do segundo lance
	if qual_time != away_team:
		if lance_ponto_2:
			var tween = create_tween()
			tween.tween_property(lance_ponto_2, "modulate", cor_atual_time, duracao_tween)
			
			# --- OSCILAÇÃO FLUIDA DO SEGUNDO LANCE ---
			tween_oscilacao_lance2 = create_tween()
			tween_oscilacao_lance2.set_loops()
			
			# 1. Sai do meio (rápido) e freia na ponta direita
			tween_oscilacao_lance2.tween_property(lance_ponto_2, "rotation_degrees", 25.0, 1.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				
			# 2. Sai da ponta direita (lento), cruza o meio rápido, e freia na ponta esquerda
			tween_oscilacao_lance2.tween_property(lance_ponto_2, "rotation_degrees", -25.0, 2.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				
			# 3. Sai da ponta esquerda (lento) e acelera pro meio (chega rápido pra emendar no passo 1)
			tween_oscilacao_lance2.tween_property(lance_ponto_2, "rotation_degrees", 0.0, 1.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
