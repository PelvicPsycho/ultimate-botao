extends Node
class_name MatchTimer

signal lance_acabou
signal partida_acabou

@export var tempo_maximo_lance: float = 10.0
@export var tempo_maximo_partida: float = 150.0 # 2:30

@onready var label_partida: Label = $"CanvasLayer/VSplitContainer/Label_Tempo"
@onready var progress_bar_lance: TextureProgressBar = $"CanvasLayer/TextureProgressBar_Lance"

var tempo_lance_restante: float = 0.0
var tempo_partida_restante: float = 0.0

var lance_rodando: bool = false
var partida_rodando: bool = false
var pausado: bool = false

var current_turn_value: int = 0


func _ready() -> void:
	tempo_lance_restante = tempo_maximo_lance
	tempo_partida_restante = tempo_maximo_partida
	_atualizar_label_partida()
	_atualizar_barra_lance()
	_atualizar_cor_barra()


func iniciar_partida() -> void:
	tempo_partida_restante = tempo_maximo_partida
	partida_rodando = true
	_atualizar_label_partida()


func iniciar_lance(turn_value: int) -> void:
	current_turn_value = turn_value
	tempo_lance_restante = tempo_maximo_lance
	lance_rodando = true
	pausado = false
	_atualizar_barra_lance()
	_atualizar_cor_barra()


func pausar_lance() -> void:
	pausado = true


func retomar_lance() -> void:
	pausado = false


func parar_tudo() -> void:
	lance_rodando = false
	partida_rodando = false
	pausado = false


func _process(delta: float) -> void:
	if partida_rodando:
		tempo_partida_restante -= delta
		_atualizar_label_partida()

		if tempo_partida_restante <= 0.0:
			tempo_partida_restante = 0.0
			partida_rodando = false
			partida_acabou.emit()
			return

	if not lance_rodando:
		return

	if pausado:
		return

	tempo_lance_restante -= delta
	_atualizar_barra_lance()

	if tempo_lance_restante <= 0.0:
		tempo_lance_restante = 0.0
		lance_rodando = false
		_atualizar_barra_lance()
		lance_acabou.emit()
func _atualizar_label_partida() -> void:
	if label_partida == null:
		return

	var minutos := int(tempo_partida_restante) / 60
	var segundos := int(tempo_partida_restante) % 60
	label_partida.text = "%02d:%02d" % [minutos, segundos]


func _atualizar_barra_lance() -> void:
	if progress_bar_lance == null:
		return

	progress_bar_lance.min_value = 0
	progress_bar_lance.max_value = tempo_maximo_lance
	progress_bar_lance.value = tempo_lance_restante
func resetar_barra_lance() -> void:
	tempo_lance_restante = tempo_maximo_lance
	if progress_bar_lance:
		progress_bar_lance.max_value = tempo_maximo_lance
		progress_bar_lance.min_value = 0
		progress_bar_lance.value = tempo_maximo_lance

func _atualizar_cor_barra() -> void:
	if progress_bar_lance == null:
		return

	if current_turn_value == 0:
		progress_bar_lance.self_modulate = Color(0.2, 0.5, 1.0, 1.0) # HOME
	else:
		progress_bar_lance.self_modulate = Color(1.0, 0.3, 0.3, 1.0) # AWAY
