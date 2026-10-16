extends RefCounted

const LEGACY_BASIC_OBS_SPACE = 27648

# Persiste apenas os valores Q; estado/ação anterior pertencem a cada arena.
static func load_table(path: String, observations: int, actions: int, schema: String) -> Matrix:
	return _load_table(path, observations, actions, schema, 0)


static func load_legacy_basic_table(path: String, observations: int, actions: int, schema: String) -> Matrix:
	return _load_table(path, observations, actions, schema, LEGACY_BASIC_OBS_SPACE)


static func _load_table(path: String, observations: int, actions: int, schema: String, legacy_observations: int) -> Matrix:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Não foi possível abrir a Q-table: %s" % path)
		return null
	var payload = file.get_var()
	if not payload is Dictionary:
		push_warning("Q-table inválida: %s" % path)
		return null
	# Arquivos antigos de QLearning.save não possuem schema.
	var saved_observations = payload.get("observation_space")
	var padded_legacy: bool = not payload.has("schema") and legacy_observations > observations and saved_observations == legacy_observations
	if payload.get("schema", schema) != schema or (saved_observations != observations and not padded_legacy) or payload.get("action_spaces") != actions:
		push_warning("Q-table incompatível com o encoder atual: %s" % path)
		return null
	var values = payload.get("QTable")
	if not values is Array or values.size() != saved_observations:
		push_warning("Número de estados inválido na Q-table: %s" % path)
		return null
	for row in values:
		if not row is Array or row.size() != actions:
			push_warning("Número de ações inválido na Q-table: %s" % path)
			return null
		for value in row:
			if not (value is float or value is int) or not is_finite(float(value)):
				push_warning("Valor inválido na Q-table: %s" % path)
				return null
	var table := Matrix.new(observations, actions)
	# O encoder básico antigo só alcançava 576 estados, mas alocava 27648 linhas.
	table.data = values.slice(0, observations) if padded_legacy else values
	if padded_legacy:
		print("Q-table básica migrada: preservados os %d estados alcançáveis do encoder antigo." % observations)
	return table


static func save_table(path: String, table: Matrix, schema: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar a Q-table: %s (erro %s)" % [path, FileAccess.get_open_error()])
		return false
	file.store_var({
		"schema": schema,
		"observation_space": table.rows,
		"action_spaces": table.cols,
		"QTable": table.data,
	})
	file.flush()
	var error := file.get_error()
	if error != OK:
		push_error("Falha ao gravar Q-table: %s (erro %s)" % [path, error])
	return error == OK
