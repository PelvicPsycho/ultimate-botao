extends Node
class_name MatchTimer

signal lance_acabou
signal partida_acabou

signal time_label_changed

signal _atualizar_barra_lance
signal resetar_barra_lance
#signal _atualizar_cor_barra

@export var tempo_maximo_lance: float = 10.0
@export var tempo_maximo_partida: float = 150.0 # 2:30


var tempo_lance_restante: float = 0.0
var tempo_partida_restante: float = 0.0

var lance_rodando: bool = false
var partida_rodando: bool = false
var pausado: bool = false

var current_turn_value: int = 0

@export_group("Áudio do Timer")
@export var audio_tempo_acabando: AudioStream

var sfx_relogio_atual: AudioStreamPlayer
var tocando_alerta: bool = false
var pitch_alerta_atual: float = 1.0

func _ready() -> void:
	tempo_lance_restante = tempo_maximo_lance
	tempo_partida_restante = tempo_maximo_partida
	time_label_changed.emit(tempo_partida_restante)
	_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
	#_atualizar_cor_barra.emit()


func iniciar_partida() -> void:
	tempo_partida_restante = tempo_maximo_partida
	partida_rodando = true
	time_label_changed.emit(tempo_partida_restante)


func iniciar_lance(turn_value: int) -> void:
	current_turn_value = turn_value
	tempo_lance_restante = tempo_maximo_lance
	lance_rodando = true
	pausado = false
	_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
	#_atualizar_cor_barra.emit()
	pitch_alerta_atual = 1.0
	parar_alerta_sonoro()
	if tocando_alerta and is_instance_valid(sfx_relogio_atual):
		sfx_relogio_atual.stop()
		tocando_alerta = false


func pausar_lance() -> void:
	pausado = true


func retomar_lance() -> void:
	pausado = false


func parar_tudo() -> void:
	lance_rodando = false
	partida_rodando = false
	pausado = false


func _process(delta: float) -> void:
	if pausado:
		return
	if partida_rodando:
		tempo_partida_restante -= delta
		time_label_changed.emit(tempo_partida_restante)

		if tempo_partida_restante <= 0.0:
			tempo_partida_restante = 0.0
			partida_rodando = false
			partida_acabou.emit()
			return

	if not lance_rodando:
		parar_alerta_sonoro()
		return

	tempo_lance_restante -= delta
	_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)

# Quando o tempo baixar de 3 segundos, dispara o áudio uma vez
	if tempo_lance_restante <= 5.0 and not tocando_alerta:
		tocar_proximo_alerta()

	if tempo_lance_restante <= 0.0:
		tempo_lance_restante = 0.0
		lance_rodando = false
		if tocando_alerta and is_instance_valid(sfx_relogio_atual):
			sfx_relogio_atual.stop()
			tocando_alerta = false
		_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
		lance_acabou.emit()
	
func call_resetar_barra_lance() -> void:
	resetar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)

func tocar_proximo_alerta() -> void:
	if not lance_rodando or pausado: return
	
	tocando_alerta = true
	var sfx = SoundMaster.play_sfx(audio_tempo_acabando, pitch_alerta_atual, 0.0)
	
	if sfx:
		# Conecta o sinal 'finished' para tocar o próximo loop
		if not sfx.finished.is_connected(tocar_proximo_alerta):
			sfx.finished.connect(_on_alerta_som_terminou, CONNECT_ONE_SHOT)

func _on_alerta_som_terminou() -> void: #arrumar o som aqui para nao ficar com o apito
	if tocando_alerta and tempo_lance_restante > 0:
		# Aumenta o pitch em 33% (fator 1.33)
		pitch_alerta_atual *= 1.1
		# Limita o pitch para não ficar agudo demais e "sumir" (opcional)
		pitch_alerta_atual = min(pitch_alerta_atual, 2.0)
		tocar_proximo_alerta()

func parar_alerta_sonoro() -> void:
	tocando_alerta = false
	if is_instance_valid(sfx_relogio_atual):
		sfx_relogio_atual.stop()
