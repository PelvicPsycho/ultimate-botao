extends CanvasLayer

@export var placar_esq: Label
@export var placar_dir: Label
@export var nome_time_esq: Label
@export var nome_time_dir: Label
@export var lateral_quem_joga: TextureRect
@export var lateral_time_esq: TextureRect
@export var lateral_time_dir: TextureRect
@export var cor_placar_esq: TextureRect
@export var cor_placar_dir: TextureRect
@export var lances_esq: Array[TextureRect]
@export var lances_dir: Array[TextureRect]
var time_home: Team #esquerda
var time_away: Team #direita
@export var pause_menu: CanvasLayer

var current_turn_value: int = 0


@export var label_tempo: Label
@export var team_barra_Lance: TextureProgressBar
@export var timer_background: TextureRect

func UI_start(team_home, team_away) -> void:
	lateral_time_esq.modulate = team_home.cor
	lateral_time_dir.modulate = team_away.cor
	cor_placar_esq.modulate = team_home.cor
	cor_placar_dir.modulate = team_away.cor
	nome_time_esq.text = team_home.name
	nome_time_dir.text = team_away.name
	time_home = team_home
	time_away = team_away

func colorir_turno(time_jogando, lances) -> void:
	# A lateral continua com modulate, pois é inteira de uma cor só
	lateral_quem_joga.modulate = time_jogando.cor
	timer_background.modulate = time_jogando.cor
	
	if time_jogando == time_home:
		# Pinta o time Esquerdo
		for i in range(lances_esq.size()):
			if i <= lances:
				lances_esq[i].set_instance_shader_parameter("cor_da_bolinha", time_jogando.cor)
				lances_esq[i].set_instance_shader_parameter("espessura_contorno", 2.0)
			else:
				lances_esq[i].set_instance_shader_parameter("cor_da_bolinha", Color.GRAY)
				lances_esq[i].set_instance_shader_parameter("espessura_contorno", 0.0)
				
		# Zera o time Direito
		for bolinha in lances_dir:
			bolinha.set_instance_shader_parameter("cor_da_bolinha", Color.GRAY)
			bolinha.set_instance_shader_parameter("espessura_contorno", 0.0)
			
	else:
		# Pinta o time Direito
		for i in range(lances_dir.size()):
			if i <= lances:
				lances_dir[i].set_instance_shader_parameter("cor_da_bolinha", time_jogando.cor)
				lances_dir[i].set_instance_shader_parameter("espessura_contorno", 2.0)
			else:
				lances_dir[i].set_instance_shader_parameter("cor_da_bolinha", Color.GRAY)
				lances_dir[i].set_instance_shader_parameter("espessura_contorno", 0.0)
				
		# Zera o time Esquerdo
		for bolinha in lances_esq:
			bolinha.set_instance_shader_parameter("cor_da_bolinha", Color.GRAY)
			bolinha.set_instance_shader_parameter("espessura_contorno", 0.0)


# %MatchUI.UI_start(homeTeam,awayTeam)

#	if currentTurn == turn.HOME:
#		%MatchUI.colorir_turno(homeTeam,turnCounter) 
#	else: %MatchUI.colorir_turno(awayTeam,turnCounter)
# adicionar no matchstate /\

func _on_botao_pause_pressed() -> void:
	pause_menu.alternar_pause()
	pass # Replace with function body.

func _atualizar_label_partida(time: float) -> void:
	print("AAAAAAAAAAAAAAAAAA")
	
	var minutos := int(time) / 60
	var segundos := int(time) % 60
	label_tempo.text = "%02d:%02d" % [minutos, segundos]

func _atualizar_barra_lance(tempo_lance_restante: float, tempo_maximo_lance: float) -> void:
	if team_barra_Lance == null:
		return

	team_barra_Lance.min_value = 0
	team_barra_Lance.max_value = tempo_maximo_lance
	team_barra_Lance.value = tempo_lance_restante

func resetar_barra_lance(tempo_lance_restante: float, tempo_maximo_lance: float) -> void:
	tempo_lance_restante = tempo_maximo_lance
	if team_barra_Lance:
		team_barra_Lance.max_value = tempo_maximo_lance
		team_barra_Lance.min_value = 0
		team_barra_Lance.value = tempo_maximo_lance

#func _atualizar_cor_barra() -> void:
	#if team_barra_Lance == null:
		#return
#
	#if current_turn_value == 0:
		#team_barra_Lance.self_modulate = Color(0.2, 0.5, 1.0, 1.0) # HOME
	#else:
		#team_barra_Lance.self_modulate = Color(1.0, 0.3, 0.3, 1.0) # AWAY
