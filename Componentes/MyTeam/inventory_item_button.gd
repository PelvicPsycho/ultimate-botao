extends Button
class_name InventoryItemButton

@export var nome_label : Label
@export var imagem_icone : TextureRect 

var item_data: Resource 

func setup_item(dados: Resource):
	item_data = dados
	
	if dados is CardResource: # se é carta
		nome_label.text = dados.nome
		if dados.arte:
			imagem_icone.texture = dados.arte
			
	elif dados is TeamPlayer: # se é peça
		nome_label.text = dados.nome
		# Precisa implementar o visual da peca
		# imagem_icone.texture = dados.icone_da_peca
