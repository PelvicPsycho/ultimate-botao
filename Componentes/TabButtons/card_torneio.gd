extends MarginContainer

# Ajuste os caminhos dos nós conforme a sua árvore exata dentro da carta
@export var label_titulo: Label
@export var label_rank: Label
@export var botao_aceitar: TextureButton # Ajuste o caminho do nó

var cup_data: Cup

func setup(novo_cup: Cup):
	cup_data = novo_cup
	
	# Atualiza os textos visuais
	label_titulo.text = cup_data.cupName
	
	# Pega o nome do Enum (S, A, B...) em formato de String baseando-se no número salvo
	var letra_do_rank = Cup.CUP_RANK.keys()[cup_data.cupRank]
	label_rank.text = "Rank " + letra_do_rank

func definir_foco(ativo: bool):
	# Essa função continua igual, controlando o botão verde
	botao_aceitar.visible = ativo
	botao_aceitar.disabled = !ativo
