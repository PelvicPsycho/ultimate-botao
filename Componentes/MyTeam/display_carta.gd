extends AspectRatioContainer

@export var pa_label: Label
@export var slots_label: Label
@export var nome_label: Label
@export var arte_texturerect: TextureRect
@export var icone_texturerect: TextureRect


func setup (carta:CardResource): #Abrir tb inventario de cartas quando tocar nisso
	pa_label.text = str(carta.custo_energia)
	slots_label.text = str(carta.custoSlotes)
	#nome_label.text = str(carta.nome)
	nome_label.texto_auto_ajustavel = str(carta.nome)
	if carta.arte:
		arte_texturerect.texture = carta.arte
	
#	if carta.icone:
#		icone_texturerect.texture = carta.icone
