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
		return

	tempo_lance_restante -= delta
	_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)

	if tempo_lance_restante <= 0.0:
		tempo_lance_restante = 0.0
		lance_rodando = false
		_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
		lance_acabou.emit()
	
func call_resetar_barra_lance() -> void:
	resetar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
