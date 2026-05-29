extends Node
class_name MatchTimer

signal partida_acabou

signal time_label_changed

#signal _atualizar_cor_barra
@export var tempo_maximo_partida: float = 90.0 # em segundos

var tempo_partida_restante: float = 0.0
var partida_rodando: bool = false
var current_turn_value: int = 0

var endGameEmitted:bool = false

func _ready() -> void:
	tempo_partida_restante = tempo_maximo_partida
	time_label_changed.emit(tempo_partida_restante)
	#_atualizar_cor_barra.emit()


func iniciar_partida() -> void:
	tempo_partida_restante = tempo_maximo_partida
	partida_rodando = false
	time_label_changed.emit(tempo_partida_restante)

func rodando_lance():
	partida_rodando = true

func acabando_lance():
	partida_rodando = false

func parar_tudo() -> void:
	partida_rodando = false

func _process(delta: float) -> void:
	if partida_rodando:
		tempo_partida_restante -= delta
		time_label_changed.emit(tempo_partida_restante)

		if tempo_partida_restante <= 0.0 and !endGameEmitted:
			endGameEmitted = true
			tempo_partida_restante = 0.0
			partida_rodando = false
			partida_acabou.emit()
			return
