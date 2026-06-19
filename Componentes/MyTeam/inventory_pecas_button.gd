extends Button

@export var nome_label: Label
@export var peca_visual: PecaMenuUI
@export var rank_label: Label
@export var quantidade_label: Label
@export var borda_panel: Panel

func _ready() -> void:
	# Garante que a borda comece invisível e o botão permita seleção
	if borda_panel:
		borda_panel.visible = false
		borda_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # Evita que o painel bloqueie cliques
		
	toggle_mode = true # Ativa o modo interruptor do botão
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	if borda_panel:
		borda_panel.visible = toggled_on

## quantidade: se > 1, mostra o label com o número. 0 ou omitido = invisível.
func setup_item(dados: Resource, quantidade: int = 0):
	if dados is TeamPlayer:
		if nome_label:
			nome_label.text = dados.nome
			
		if rank_label:
			dados.estimateRank()
			var dadosRank = dados.rank
			var rank_keys := TeamPlayer.Rank.keys()
			if typeof(dadosRank) == TYPE_INT and dadosRank >= 0 and dadosRank < rank_keys.size():
				rank_label.text = rank_keys[dadosRank]
			else:
				rank_label.text = str(dadosRank)
		
		if is_instance_valid(peca_visual):
#			peca_visual.show()
			peca_visual.setup_peca(dados)
	
	if quantidade_label:
		quantidade_label.visible = quantidade > 1
		if quantidade > 1:
			quantidade_label.text = str(quantidade)
