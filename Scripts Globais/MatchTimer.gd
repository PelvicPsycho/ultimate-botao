extends Node
class_name MatchTimer

enum TimerType {TIMER, CHESS, SHOTS}

signal partida_acabou
signal lance_acabou

signal time_label_changed
signal lance_label_changed(isHome: bool, value: float)

@export var tipo_do_timer: TimerType = TimerType.TIMER

func _ready() -> void:
	tipo_do_timer  = GameState.TimerType
	match tipo_do_timer:
		TimerType.TIMER:
			tempo_partida_restante = tempo_maximo_partida
			time_label_changed.emit(tempo_partida_restante)
		TimerType.SHOTS:
			totalShotsRemaining = totalShots
			time_label_changed.emit(totalShotsRemaining)

	#_atualizar_cor_barra.emit()

func iniciar_partida(startHome: bool = false) -> void:
	isHomeTurn = startHome
	tipo_do_timer  = GameState.TimerType
	match tipo_do_timer:
		TimerType.TIMER:
			tempo_partida_restante = tempo_maximo_partida
			tempo_lance_restante = tempo_maximo_lance
			partida_rodando = false
			time_label_changed.emit(tempo_partida_restante)
			lance_label_changed.emit(isHomeTurn, tempo_lance_restante)
		TimerType.SHOTS:
			totalShotsRemaining = totalShots
			partida_rodando = false
			time_label_changed.emit(totalShotsRemaining)
		TimerType.CHESS:
			homeTimeRemaining = homeTimeMax
			awayTimeRemaining = awayTimeMax
			partida_rodando = false
			time_label_changed.emit(homeTimeRemaining if isHomeTurn else awayTimeRemaining)
			lance_label_changed.emit(true, homeTimeRemaining)
			lance_label_changed.emit(false, awayTimeRemaining)
	
#region Timer
#signal _atualizar_cor_barra
@export_group("Timer")
@export var tempo_maximo_partida: float = 150.0 # em segundos
@export var tempo_maximo_lance: float = 15.0

var tempo_partida_restante: float = 0.0
var tempo_lance_restante: float = 0.0

var partida_rodando: bool = false
var lance_rodando: bool = false
var pausado: bool = false
var current_turn_value: int = 0

var endGameEmitted:bool = false

@export_group("Áudio do Timer")
@export var audio_tempo_acabando: AudioStream

var sfx_relogio_atual: AudioStreamPlayer
var tocando_alerta: bool = false
var pitch_alerta_atual: float = 1.0


func iniciar_lance(turn_value: int) -> void:
	current_turn_value = turn_value
	isHomeTurn = (turn_value == 0)
	tempo_lance_restante = tempo_maximo_lance
	lance_rodando = true
	pausado = false
	lance_label_changed.emit(isHomeTurn, tempo_lance_restante)
	#_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
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

func _on_alerta_som_terminou() -> void: #arrumar o som aqui para nao ficar com o apito
	if tocando_alerta and tempo_lance_restante > 0:
		# Aumenta o pitch em 33% (fator 1.33)
		pitch_alerta_atual *= 1.1
		# Limita o pitch para não ficar agudo demais e "sumir" (opcional)
		pitch_alerta_atual = min(pitch_alerta_atual, 2.0)
		tocar_proximo_alerta()

func tocar_proximo_alerta() -> void:
	if not lance_rodando or pausado: return
	
	tocando_alerta = true
	var sfx = SoundMaster.play_sfx(audio_tempo_acabando, pitch_alerta_atual, 0.0)
	
	if sfx:
		# Conecta o sinal 'finished' para tocar o próximo loop
		if not sfx.finished.is_connected(tocar_proximo_alerta):
			sfx.finished.connect(_on_alerta_som_terminou, CONNECT_ONE_SHOT)

func parar_alerta_sonoro() -> void:
	tocando_alerta = false
	if is_instance_valid(sfx_relogio_atual):
		sfx_relogio_atual.stop()

#endregion

#region Shots

@export_group("Shots")
@export var totalShots: int = 30
var totalShotsRemaining: int = 0

func countShot():
	totalShotsRemaining -= 1
	time_label_changed.emit(totalShotsRemaining)
	if totalShotsRemaining <= 0 and !endGameEmitted:
		endGameEmitted = true
		tempo_partida_restante = 0.0
		partida_rodando = false
		partida_acabou.emit()

#endregion

#region Chess

@export_group("Chess")
@export var homeTimeMax: float = 75.0
@export var awayTimeMax: float = 75.0
@export var additionalTime: float = 10.0

var homeTimeRemaining: float
var awayTimeRemaining: float

var isHomeTurn: bool = false

signal punishTeam(isHome: bool)

func addTime(isHome:bool):
	if isHome:
		homeTimeRemaining += additionalTime
	else:
		awayTimeRemaining += additionalTime

func resetTimer(isHome:bool):
	if isHome:
		homeTimeRemaining += homeTimeMax/2
	else:
		awayTimeRemaining += awayTimeMax/2

#endregion

func _process(delta: float) -> void:
	if pausado:
		return
	if partida_rodando:
		match tipo_do_timer:
			TimerType.TIMER:
				tempo_partida_restante -= delta
				time_label_changed.emit(tempo_partida_restante)
				# emitir o label changed pra progress bar de lance
				if lance_rodando:
					tempo_lance_restante -= delta
					lance_label_changed.emit(isHomeTurn, tempo_lance_restante)
					if tempo_lance_restante <= 5.0 and not tocando_alerta:
						tocar_proximo_alerta()
					if tempo_lance_restante <= 0.0:
						tempo_lance_restante = 0.0
						lance_rodando = false
						if tocando_alerta and is_instance_valid(sfx_relogio_atual):
							sfx_relogio_atual.stop()
							tocando_alerta = false
						#_atualizar_barra_lance.emit(tempo_lance_restante, tempo_maximo_lance)
						lance_acabou.emit()
			
				if tempo_partida_restante <= 0.0 and !endGameEmitted:
					endGameEmitted = true
					tempo_partida_restante = 0.0
					partida_rodando = false
					partida_acabou.emit()
					return
					
			TimerType.CHESS:
				if isHomeTurn:
					homeTimeRemaining -= delta
					time_label_changed.emit(homeTimeRemaining)
					lance_label_changed.emit(true, homeTimeRemaining)
					if homeTimeRemaining <= 0.0:
						punishTeam.emit(true)
				else:
					awayTimeRemaining -= delta
					time_label_changed.emit(awayTimeRemaining)
					lance_label_changed.emit(false, awayTimeRemaining)
					if awayTimeRemaining <= 0.0:
						punishTeam.emit(false)
