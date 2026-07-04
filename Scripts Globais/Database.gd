extends Node

# Dicionários globais que mapeiam a String (ID) para o Resource físico
var cartas_db: Dictionary = {}
var pecas_db: Dictionary = {}

func _ready() -> void:
	print("Carregando Banco de Dados Global...")
	_carregar_db_cartas("res://Componentes/Cartas/CardResorce/")
	_carregar_db_pecas("res://Recursos/Teams/")  # Varre todas as pastas de rank e times recursivamente
	print("Database de Peças carregado: ", pecas_db.size(), " peças encontradas.")

func _carregar_db_cartas(pasta: String) -> void:
	if not pasta.ends_with("/"): pasta += "/"
	
	var dir = DirAccess.open(pasta)
	if not dir:
		push_error("Database: Não foi possível abrir a pasta: " + pasta)
		return
	
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		var nome_limpo = file.replace(".remap", "")
		if nome_limpo.ends_with(".tres") or nome_limpo.ends_with(".res"):
			var recurso = load(pasta + nome_limpo)
			if recurso is CardResource:
				# Aqui usamos o ID único que você configurou no CardResource
				cartas_db[recurso.id_unico] = recurso
		file = dir.get_next()
	dir.list_dir_end()
			
	print("Database de Cartas carregado: ", cartas_db.size(), " cartas encontradas.")

func get_carta(id: StringName) -> CardResource:
	return cartas_db.get(id, null)

# Busca recursiva nas subpastas do /Teams/
# Suporta qualquer profundidade: Teams/Rank/Time/arquivo.tres
func _carregar_db_pecas(pasta: String) -> void:
	if not pasta.ends_with("/"): pasta += "/"
	
	var dir = DirAccess.open(pasta)
	if not dir:
		push_error("Database: Não foi possível abrir a pasta: " + pasta)
		return
	
	dir.list_dir_begin()
	var file = dir.get_next()
	
	while file != "":
		if dir.current_is_dir():
			# Ignora os atalhos de sistema "." e ".."
			if file != "." and file != "..":
				_carregar_db_pecas(pasta + file + "/")
		else:
			var nome_limpo = file.replace(".remap", "")
			if nome_limpo.ends_with(".tres") or nome_limpo.ends_with(".res"):
				var recurso = load(pasta + nome_limpo)
				
				# --- TRAVA DE SEGURANÇA ---
				# Garante que só vamos tentar ler e alterar se o arquivo for uma Peça!
				if recurso is TeamPlayer:
					# NÃO modifica o resource compartilhado! Apenas armazena a referência.
					# O ajuste de slotsUpgrates agora é feito no setter de quantosSlotes
					# e no SaveManager.load_game() ao duplicar a peça.
					pecas_db[recurso.id_unico] = recurso
					
		file = dir.get_next()
	
	dir.list_dir_end()
