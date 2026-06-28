extends AspectRatioContainer

@export var pa_label: Label
@export var slots_label: Label
@export var nome_label: Label
@export var arte_texturerect: TextureRect
@export var icone_texturerect: TextureRect


func setup (carta:CardResource):
	pa_label.text = str(carta.custo_energia)
	slots_label.text = str(carta.custoSlotes)
	#nome_label.text = str(carta.nome)
	nome_label.texto_auto_ajustavel = str(carta.nome)
	if carta.display_arte:
		arte_texturerect.texture = carta.display_arte
	
	if carta.arte:
		icone_texturerect.texture = carta.arte
