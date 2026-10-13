class_name ApproximateQLearning
extends QLearning

# Estrutura de pesos e espaços
var feature_count: int
var weights: Array[float] = []

# Memória de temporal difference
var previous_features: Array[float] = []
var previous_q: float = 0.0

func _init(n_features: int, n_action_spaces: int, _is_learning: bool = true) -> void:
	feature_count = n_features
	action_spaces = n_action_spaces
	is_learning = _is_learning
	
	weights.resize(feature_count)
	weights.fill(0.0)

# Calcula Q(s, a) via Produto Escalar entre pesos e features
func get_q_value(features: Array[float]) -> float:
	var q = 0.0
	for i in range(weights.size()):
		q += weights[i] * features[i]
	return q

# Predição compatível com AQL
# 'get_features_for_action_cb' é um Callable que retorna a lista de features para uma dada ação: func(action_int) -> Array[float]
func predict_aql(get_features_for_action_cb: Callable, reward_of_previous_state: float, is_terminal: bool = false) -> int:
	var action_to_take: int = 0
	var max_future_q: float = -INF
	var best_actions: Array[int] = []
	var features_per_action: Array = []
	
	# 1. Avalia o estado futuro para todas as ações possíveis
	if not is_terminal:
		for a in range(action_spaces):
			var f: Array[float] = get_features_for_action_cb.call(a)
			features_per_action.append(f)
			var q = get_q_value(f)
			
			if q > max_future_q:
				max_future_q = q
				best_actions = [a]
			elif q == max_future_q:
				best_actions.append(a)
	else:
		max_future_q = 0.0 # Sem futuro após fim de episódio

	# 2. Atualização dos Pesos via Gradient Descent (TD Error)
	if is_learning and previous_features.size() > 0:
		var td_error = reward_of_previous_state + (discounted_factor * max_future_q) - previous_q
		for i in range(weights.size()):
			weights[i] += learning_rate * td_error * previous_features[i]

	# Se for terminal, limpa a memória e encerra
	if is_terminal:
		previous_features.clear()
		previous_q = 0.0
		previous_action = -1
		return -1

	# 3. Seleção da Ação (Epsilon-Greedy)
	if randf() < exploration_probability and is_learning:
		action_to_take = randi_range(0, action_spaces - 1)
	else:
		action_to_take = best_actions.pick_random()

	# 4. Atualização de Memória e Epsilon Decay
	previous_features = features_per_action[action_to_take]
	previous_q = get_q_value(previous_features)
	previous_action = action_to_take
	steps_completed += 1

	if is_learning and decay_per_steps != 0 and steps_completed % decay_per_steps == 0:
		exploration_probability = maxf(min_exploration_probability, exploration_probability - exploration_decreasing_decay)

	return action_to_take

# Serialização compatível com o formato do seu Addon
func to_dict() -> Dictionary:
	return {
		"feature_count": feature_count,
		"action_spaces": action_spaces,
		"weights": weights,
		"exploration_probability": exploration_probability,
		"exploration_decreasing_decay": exploration_decreasing_decay,
		"min_exploration_probability": min_exploration_probability,
		"discounted_factor": discounted_factor,
		"learning_rate": learning_rate,
		"decay_per_steps": decay_per_steps,
		"steps_completed": steps_completed,
		"is_learning": is_learning
	}

func from_dict(dict: Dictionary) -> void:
	feature_count = dict["feature_count"]
	action_spaces = dict["action_spaces"]
	weights = dict["weights"]
	exploration_probability = dict["exploration_probability"]
	exploration_decreasing_decay = dict["exploration_decreasing_decay"]
	min_exploration_probability = dict["min_exploration_probability"]
	discounted_factor = dict["discounted_factor"]
	learning_rate = dict["learning_rate"]
	decay_per_steps = dict["decay_per_steps"]
	steps_completed = dict["steps_completed"]
	is_learning = dict["is_learning"]

func save(file_path: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(self.to_dict())
		file.close()

func load(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		var dict: Dictionary = file.get_var()
		file.close()
		self.from_dict(dict)
