extends Button

@export var nome_label: Label
@export var foto_icone: TextureRect
@export var rank_label: Label
@export var quantidade_label: Label

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

	if quantidade_label:
		quantidade_label.visible = quantidade > 1
		if quantidade > 1:
			quantidade_label.text = str(quantidade)
