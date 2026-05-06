extends Resource
class_name CardResource

enum TipoEfeito {
	FORCA,
	PA
	
}
enum Raridade{
	NORMAL, INCOMUN, RARA
}
enum TipoAlvo {
	PROPRIA_PECA,
	BOLA,
	ADVERSARIO
}

@export var nome: String = ""
@export var custo_energia: int = 0
@export var arte: Texture2D
@export var descricao: String = ""
@export var tipo_efeito: TipoEfeito
@export var tipo_alvo: TipoAlvo
@export var raridade:Raridade
@export var magnitude:int
