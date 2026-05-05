extends TextureButton

@onready var artwork: TextureRect = $TextureRect/Control/ImagemCarta
@onready var name_label: Label = $TextureRect/Control3/NomeCard
@onready var cost_label: Label = $TextureRect/Control2/Custo
signal carta_clicada(resource_vinculado)


var _resource_pendente: CardResource

func _ready():
	# Isso força o nó a ignorar os filhos e focar no clique da raiz
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func configurar(resource: CardResource) -> void:
	_resource_pendente = resource

	if not is_node_ready():
		await ready
	if resource.arte:
		artwork.texture = resource.arte
		
	else:
		print("❌ Textura é Nil, não consigo atribuir")
	artwork.texture = resource.arte
	name_label.text = resource.nome
	cost_label.text = str(resource.custo_energia)
func _on_pressed() -> void:
	
	carta_clicada.emit(_resource_pendente)
