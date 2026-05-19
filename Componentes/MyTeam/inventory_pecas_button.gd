extends Button

@export var nome_label: Label
@export var foto_icone: TextureRect
@export var rank_label: Label
# Adicione outras variáveis pro visual da peça (ex: ícone de posição, moldura, etc)

func setup_item(dados: Resource):
	if dados is TeamPlayer:
		nome_label.text = dados.nome
#		if dados.foto:
#			foto_icone.texture = dados.foto
		if dados.rank:
			rank_label.text = str(dados.rank)
