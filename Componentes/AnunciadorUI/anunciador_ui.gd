extends CanvasLayer

@onready var label = $TextoApenas_Control/Label
@onready var lances_control = $Lances_Control
@onready var video_player = $Lances_Control/VideoStreamPlayer
@onready var jogador_label = $Lances_Control/Jogador_Label
@onready var lances_label = $Lances_Control/Lances_Label


@export var distancia_do_centro: float = 150
@export_group("🎬 Velocidades de entrada (Fase 1)")
@export_range(0.1, 2.0, 0.05) var entrada_video_s: float = 0.2
@export_range(0.1, 2.0, 0.05) var entrada_jogador_s: float = 0.3
@export_range(0.1, 2.0, 0.05) var entrada_lances_s: float = 0.4

@export_group("🐌 Deslize lento (Fase 2)")
@export_range(0.5, 5.0, 0.1) var deslize_duracao_s: float = 2.0
@export_range(50.0, 800.0, 10.0) var deslize_distancia_video_px: float = 50.0
@export_range(50.0, 800.0, 10.0) var deslize_distancia_jogador_px: float = 90.0
@export_range(50.0, 800.0, 10.0) var deslize_distancia_lances_px: float = 180.0

@export_group("💨 Disparo final (Fase 3)")
@export_range(0.1, 1.0, 0.05) var disparo_duracao_s: float = 0.3

@export_group("⏳ Pausa pós-disparo (Fase 4)")
@export_range(0.0, 2.0, 0.1) var pausa_final_s: float = 0.1

var animacao_atual: Tween
var animacao_interface_atual: Tween

# Posições originais de centro — guardadas uma vez no _ready()
# para nunca serem corrompidas pela animação.
var video_center_x: float
var jogador_center_x: float
var lances_center_x: float

signal anuncio_encerrado
signal evento_interface_encerrado

func _ready():
	# Esconde o texto quando o jogo começa
	label.modulate.a = 0.0
	lances_control.visible = false

	# Guarda as posições originais de centro de cada elemento
	video_center_x = video_player.position.x
	jogador_center_x = jogador_label.position.x
	lances_center_x = lances_label.position.x

# Esta é a função que você vai chamar de outros scripts!
func mostrar_evento(texto: String, tamanho: int, tempo_na_tela: float, cor: Color = Color.WHITE) -> void:
	label.visible = true
	# 1. Configura o visual
	label.text = texto
	label.label_settings.font_size = tamanho
	label.label_settings.font_color = cor
	
	# 2. Cancela a animação anterior se ela ainda estiver tocando
	if animacao_atual and animacao_atual.is_valid():
		animacao_atual.kill()
		
	# 3. Prepara as posições iniciais
	label.scale = Vector2(0.1, 0.1) # Começa minúsculo
	label.modulate.a = 0.0          # Começa invisível
	
	# 4. Cria a nova animação
	animacao_atual = create_tween()
	
	# PASSO A: O texto "estoura" na tela (Efeito elástico)
	animacao_atual.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacao_atual.tween_property(label, "scale", Vector2(1, 1), 0.4)
	animacao_atual.parallel().tween_property(label, "modulate:a", 1.0, 0.2)
	
	# PASSO B: O texto fica parado na tela o tempo que você pediu
	animacao_atual.tween_interval(tempo_na_tela)
	
	# PASSO C: O texto some voando e ficando transparente
	animacao_atual.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	animacao_atual.tween_property(label, "scale", Vector2(2, 2), 0.3)
	animacao_atual.parallel().tween_property(label, "modulate:a", 0.0, 0.3)
	animacao_atual.finished.connect(_avisar_fim_do_anuncio)

func _avisar_fim_do_anuncio() -> void:
	label.visible = false
	anuncio_encerrado.emit()

# EXEMPLOS \/
"""
func fazer_gol():
	# GOL! Gigante, vermelho, fica 2 segundos na tela
	mostrar_evento("GOOOL!
	DO INTER", 120, 2.0, Color.RED)

func mudar_turno(nome_do_time):
	# Turno do time. Médio, fica 1.5 segundos
	mostrar_evento("Turno: " + nome_do_time, 80, 1.5, Color.WHITE)
"""
func lance_acertou():
	# Continua! Pequeno, amarelo, sai da tela rapidão (0.5s) para não travar o jogo
	mostrar_evento("Continua!", 60, 0.5, Color.YELLOW)
	
func iniciar_partida():
	mostrar_evento("COMEÇA A PARTIDA", 100, 2.0, Color.GREEN)

# ────────────────────────────────────────────────────────────────────
#   NOVA FUNÇÃO: animação de interface com vídeo + 2 labels
# ────────────────────────────────────────────────────────────────────
#   Todos entram da esquerda em velocidades diferentes (vídeo é o
#   mais rápido pra chegar ao centro), depois deslizam lentamente
#   para a direita por 2s (vídeo é o mais lento), depois disparam
#   para fora da tela à direita. Meio segundo após o disparo,
#   emite o sinal evento_interface_encerrado.
# ────────────────────────────────────────────────────────────────────
func mostrar_evento_interface(is_Home: bool = true, texto_lance: String = "1", cor_time: Color = Color.WHITE, duracao_deslize: float = 2.0) -> void:
	# Cancela animação anterior se ainda estiver rodando
	if animacao_interface_atual and animacao_interface_atual.is_valid():
		animacao_interface_atual.kill()

	# ── Aplica a cor do time no shader do vídeo ──
	video_player.material.set_shader_parameter("color_tint", cor_time)

	# ── Configura textos ──
	if is_Home:
		jogador_label.text = tr("PLAYER")
	else:
		jogador_label.text = tr("OPPONENT")
	if not texto_lance.is_empty():
		lances_label.text = texto_lance + tr("FIRST" if texto_lance == "1" else "SECOND" if texto_lance == "2" else "THIRD") + " " +tr("SHOT")

	# ── Direção da animação e flip do vídeo ──
	# Home: entra da esquerda → direita, vídeo normal
	# Away: entra da direita → esquerda, vídeo espelhado
	var dir: float
	var video_x: float
	var jogador_x: float
	var lances_x: float
	
	if is_Home:
		dir = 1.0
		video_x = video_center_x - distancia_do_centro
		jogador_x = jogador_center_x - distancia_do_centro*1.3
		lances_x = lances_center_x - distancia_do_centro*2
	else:
		dir = -1.0
		video_x = video_center_x #+ distancia_do_centro
		jogador_x = jogador_center_x - distancia_do_centro*5.5
		lances_x = lances_center_x + distancia_do_centro
	
	
	video_player.scale.x = 1.0 if is_Home else -1.0
	
	# ── Torna tudo visível ──
	lances_control.visible = true
	video_player.visible = true
	jogador_label.visible = true
	lances_label.visible = true
	
	video_player.play()

	var screen_width: float = get_viewport().get_visible_rect().size.x
	var margem: float = 400.0
	var offset_fora: float = screen_width + margem

	# Posições iniciais (fora da tela: esquerda p/ Home, direita p/ Away)
	var video_start_x: float = video_x - dir * offset_fora
	var jogador_start_x: float = jogador_x - dir * offset_fora
	var lances_start_x: float = lances_x - dir * offset_fora

	# Posições finais (fora da tela: direita p/ Home, esquerda p/ Away)
	var video_end_x: float = video_x + dir * offset_fora
	var jogador_end_x: float = jogador_x + dir * offset_fora
	var lances_end_x: float = lances_x + dir * offset_fora

	# Aplica posições iniciais
	video_player.position.x = video_start_x
	jogador_label.position.x = jogador_start_x
	lances_label.position.x = lances_start_x

	# ── Cria a animação ──
	animacao_interface_atual = create_tween()

	# FASE 1: Entrada rápida até o centro (velocidades diferentes)
	animacao_interface_atual.tween_property(video_player, "position:x", video_x, entrada_video_s)
	animacao_interface_atual.parallel().tween_property(jogador_label, "position:x", jogador_x, entrada_jogador_s)
	animacao_interface_atual.parallel().tween_property(lances_label, "position:x", lances_x, entrada_lances_s)

	# FASE 2: Deslize lento (direita p/ Home, esquerda p/ Away)
	animacao_interface_atual.tween_property(video_player, "position:x", video_x + dir * deslize_distancia_video_px, duracao_deslize) #deslize_duracao_s)
	animacao_interface_atual.parallel().tween_property(jogador_label, "position:x", jogador_x + dir * deslize_distancia_jogador_px, duracao_deslize) #deslize_duracao_s)
	animacao_interface_atual.parallel().tween_property(lances_label, "position:x", lances_x + dir * deslize_distancia_lances_px, duracao_deslize) #deslize_duracao_s)

	# FASE 3: Disparam para fora da tela
	animacao_interface_atual.tween_property(video_player, "position:x", video_end_x, disparo_duracao_s)
	animacao_interface_atual.parallel().tween_property(jogador_label, "position:x", jogador_end_x, disparo_duracao_s)
	animacao_interface_atual.parallel().tween_property(lances_label, "position:x", lances_end_x, disparo_duracao_s)

	# FASE 4: Pausa antes de avisar o fim
	animacao_interface_atual.tween_interval(pausa_final_s)
	animacao_interface_atual.tween_callback(_avisar_fim_evento_interface)


func _avisar_fim_evento_interface() -> void:
	video_player.stop()
	lances_control.visible = false
	evento_interface_encerrado.emit()

#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("ui_left"):
#		fazer_gol()
#	if event.is_action_pressed("ui_right"):
#		iniciar_partida()


func _on_button_pressed() -> void:
	mostrar_evento_interface(true,"1",Color(0.0, 0.59, 0.58, 1.0))


func _on_button_2_pressed() -> void:
	var matchsc = get_parent()
	matchsc.congelar_jogo(true, 1)
