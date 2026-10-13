extends Node

var shared_qtable: Matrix
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

	 # cria tabela compartilhada com base no primeiro controller
	var obs_space = controllers[0].OBS_SPACE
	var act_space = controllers[0].ACT_SPACE
	shared_qtable = Matrix.new(obs_space, act_space)

	for c in controllers:
		c.set_shared_qtable(shared_qtable)

func OnGoalScoredOnArena(arenaIndex):
	print("goooooooooala OnGoalScoredOnArena")
	var arena = controllers[arenaIndex]
	arena._reset_episode()

func printStatus(arena):
	pass

func _on_timer_timeout():
	pass # Replace with function body.
