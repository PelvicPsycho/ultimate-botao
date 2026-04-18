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
	lateral_quem_joga.modulate = time_jogando.cor
	if time_jogando == time_home:
		for i in range(lances_esq.size()):
			if i <= lances:
#				print("caraio ",time_jogando.cor)
				lances_esq[i].modulate = time_jogando.cor
			else:
				lances_esq[i].modulate = Color(1.0, 1.0, 1.0, 1.0)
		for bolinha in lances_dir:
			bolinha.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		for i in range(lances_dir.size()):
			if i <= lances:
				lances_dir[i].modulate = time_jogando.cor
			else:
				lances_dir[i].modulate = Color(1.0, 1.0, 1.0, 1.0)
				
		for bolinha in lances_esq:
			bolinha.modulate = Color(1.0, 1.0, 1.0, 1.0)


# %MatchUI.UI_start(homeTeam,awayTeam)

#	if currentTurn == turn.HOME:
#		%MatchUI.colorir_turno(homeTeam,turnCounter) 
#	else: %MatchUI.colorir_turno(awayTeam,turnCounter)
# adicionar no matchstate /\


func _on_botao_pause_pressed() -> void:
	pause_menu.alternar_pause()
	pass # Replace with function body.
