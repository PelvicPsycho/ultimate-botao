extends Resource
class_name AIWeights

# Nossos "Genes" (os pesos da função de avaliação)
@export var goalWeight: float
@export var ballPossesionWeight: float 
@export var distToPlayerGoalWeight: float 
@export var distToAiGoalWeight:float 
@export var playerPiecesHitWeight:float
@export var finalPiecePositionWeight:float
@export var ownGoalWeight: float

# Variável para armazenar a nota final após a simulação
var fitness: float = 0.0

# Função para inicializar com valores aleatórios (Geração 0)
func randomize_genes():
	goalWeight = randf_range(-1000.0, 1000.0)
	ballPossesionWeight = randf_range(-1000.0, 1000.0)
	distToPlayerGoalWeight = randf_range(-1000.0, 1000.0)
	distToAiGoalWeight = randf_range(-1000.0, 1000.0)
	playerPiecesHitWeight = randf_range(-1000.0, 1000.0)
	finalPiecePositionWeight = randf_range(-1000.0, 1000.0)
	ownGoalWeight = randf_range(-1000.0, 1000.0)
