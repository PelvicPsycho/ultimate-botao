extends Button

@export var nome_label : Label
@export var imagem_icone : TextureRect
@export var quantidade_label: Label

var item_data: Resource

## quantidade: se > 1, mostra o label com o número. 0 ou omitido = invisível.
func setup_item(dados: Resource, quantidade: int = 0):
	item_data = dados
	
	if dados is CardResource:
		nome_label.text = dados.nome

	if quantidade_label:
		quantidade_label.visible = quantidade > 1
		if quantidade > 1:
			quantidade_label.text = str(quantidade)
