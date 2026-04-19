extends CanvasLayer

@onready var label = $Control/Label
var animacao_atual: Tween

signal anuncio_encerrado

func _ready():
	# Esconde o texto quando o jogo começa
	label.modulate.a = 0.0

# Esta é a função que você vai chamar de outros scripts!
func mostrar_evento(texto: String, tamanho: int, tempo_na_tela: float, cor: Color = Color.WHITE) -> void:
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
	anuncio_encerrado.emit()

# EXEMPLOS \/

func fazer_gol():
	# GOL! Gigante, vermelho, fica 2 segundos na tela
	mostrar_evento("GOOOL!
	DO INTER", 120, 2.0, Color.RED)

func mudar_turno(nome_do_time):
	# Turno do time. Médio, fica 1.5 segundos
	mostrar_evento("Turno: " + nome_do_time, 80, 1.5, Color.WHITE)

func lance_acertou():
	# Continua! Pequeno, amarelo, sai da tela rapidão (0.5s) para não travar o jogo
	mostrar_evento("Continua!", 60, 0.5, Color.YELLOW)
	
func iniciar_partida():
	mostrar_evento("COMEÇA A PARTIDA", 100, 2.0, Color.GREEN)

#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("ui_left"):
#		fazer_gol()
#	if event.is_action_pressed("ui_right"):
#		iniciar_partida()
