extends Node

const Q_WEIGHTS_PATH = "res://2D Changes/AI Training/aql-weights.dat"

var shared_aql: ApproximateQLearning
var controllers: Array = []

func _ready():
	await get_tree().process_frame
	
	for child in get_tree().get_nodes_in_group("Arena"):
		if child.has_node("QLearningTrainingController"):
			var QLTrainingController = child.get_node("QLearningTrainingController")
			QLTrainingController.connect("goalScoreOnArena", OnGoalScoredOnArena)
			controllers.append(QLTrainingController)
			
	if controllers.is_empty():
		push_error("No Controller Found")
		return

	# Obtém as dimensões a partir do primeiro controlador
	var num_features = controllers[0].NUM_FEATURES
	var act_space = controllers[0].ACT_SPACE
	
	# Instancia um único modelo AQL central para todos os agentes
	shared_aql = ApproximateQLearning.new(num_features, act_space)
	#shared_aql.load(Q_WEIGHTS_PATH)

	# Injeta a referência do AQL em cada agente
	for c in controllers:
		c.set_shared_aql(shared_aql)

func OnGoalScoredOnArena(arenaIndex: int):
	print("Gooooooal na arena: ", arenaIndex)
	if arenaIndex < controllers.size():
		var arena = controllers[arenaIndex]
		arena._reset_episode()
