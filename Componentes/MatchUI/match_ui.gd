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

func UI_start(team_home, team_away) -> void:
	lateral_time_esq.modulate = team_home.cor
	lateral_time_dir.modulate = team_away.cor
	cor_placar_esq.modulate = team_home.cor
	cor_placar_dir.modulate = team_away.cor
	nome_time_esq.text = team_home.name
	nome_time_dir.text = team_away.name
	
# %MatchUI.UI_start(homeTeam,awayTeam)
# adicionar no matchstate /\
