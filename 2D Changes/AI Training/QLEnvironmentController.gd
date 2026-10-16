extends Node

const QTableStorage = preload("res://2D Changes/AI Training/QTableStorage.gd")

var shared_qtable: Matrix
var controllers: Array = []
var _save_path: String
var _schema: String


func _ready() -> void:
	Engine.physics_ticks_per_second = 180
	Engine.max_physics_steps_per_frame = 16
	# Os filhos já executaram _ready; o treino só começa via chamada deferred.
	for arena in get_tree().get_nodes_in_group("Arena"):
		if not is_ancestor_of(arena):
			continue
		var controller = arena.get_node_or_null("QLearningTrainingController")
		if controller is QLearningTrainingController or controller is QLearningTrainingControllerPlus:
			controllers.append(controller)
	if controllers.is_empty():
		push_error("Nenhum controller Q-Learning encontrado neste ambiente.")
		return

	var first = controllers[0]
	# Mesmo tamanho não garante o mesmo significado dos estados.
	for controller in controllers:
		if controller.Q_TABLE_SCHEMA != first.Q_TABLE_SCHEMA or controller.OBS_SPACE != first.OBS_SPACE or controller.ACT_SPACE != first.ACT_SPACE:
			for candidate in controllers:
				candidate._training_blocked = true
			push_error("O ambiente exige controllers com o mesmo encoder de estados e ações.")
			controllers.clear()
			return
		if controller.should_reuse_qtable() != first.should_reuse_qtable():
			push_warning("reuseQTable divergente entre arenas; será usada a opção da primeira arena.")

	_save_path = first.Q_TABLE_PATH
	_schema = first.Q_TABLE_SCHEMA
	shared_qtable = first.load_initial_qtable()
	for controller in controllers:
		controller.set_shared_qtable(shared_qtable)
		controller.qtable_save_requested.connect(save_qtable)
		# Bind da instância evita depender da ordem do grupo ou de índices contíguos.
		controller.goalScoreOnArena.connect(_on_goal_scored.bind(controller))
	print("Q-table compartilhada: %d estados, %d ações, %d arenas." % [shared_qtable.rows, shared_qtable.cols, controllers.size()])
	print(shared_qtable.data)


func save_qtable() -> void:
	if shared_qtable != null:
		QTableStorage.save_table(_save_path, shared_qtable, _schema)


func _on_goal_scored(_arena_index: int, controller: Node) -> void:
	controller._reset_episode()


func _on_timer_timeout() -> void:
	save_qtable()
