extends Resource
class_name CardResource

enum TipoEfeito {
	IMPULSO,
	TELEPORTE,
	ESCUDO
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
@export var magnitude: float = 0.0
