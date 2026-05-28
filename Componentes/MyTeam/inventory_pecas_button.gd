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
			# Usa a lista de chaves do enum (ex: ["S", "A", "B"...]) 
			# e pega a palavra que está no índice do rank atual.
			rank_label.text = TeamPlayer.Rank.keys()[dados.rank]

	if quantidade_label:
		quantidade_label.visible = quantidade > 1
		if quantidade > 1:
			quantidade_label.text = str(quantidade)
