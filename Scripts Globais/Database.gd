extends Node

# Dicionários globais que mapeiam a String (ID) para o Resource físico
var cartas_db: Dictionary = {}
var pecas_db: Dictionary = {}

func _ready() -> void:
	print("Carregando Banco de Dados Global...")
	_carregar_db_cartas("res://Componentes/Cartas/CardResorce/")
	_carregar_db_pecas("res://Recursos/Teams/F Teams/") #Busca apenas nas SUBPastas de Teams

func _carregar_db_cartas(pasta: String) -> void:
	if not pasta.ends_with("/"): pasta += "/"
	
	var dir = DirAccess.open(pasta)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres") or file.ends_with(".res"):
				var recurso = load(pasta + file)
				if recurso is CardResource:
					# Aqui usamos o ID único que você configurou no CardResource
					cartas_db[recurso.id_unico] = recurso
			file = dir.get_next()
			
	print("Database de Cartas carregado: ", cartas_db.size(), " cartas encontradas.")

func get_carta(id: StringName) -> CardResource:
	return cartas_db.get(id, null)

#Busca recursiva nas subpastas do /Teams/
func _carregar_db_pecas(pasta: String) -> void:
	if not pasta.ends_with("/"): pasta += "/"
	
	var dir = DirAccess.open(pasta)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		
		while file != "":
			if dir.current_is_dir():
				# Ignora os atalhos de sistema "." e ".."
				if file != "." and file != "..":
					_carregar_db_pecas(pasta + file + "/")
			else:
				if file.ends_with(".tres") or file.ends_with(".res"):
					var recurso = load(pasta + file)
					
					# --- TRAVA DE SEGURANÇA ---
					# Garante que só vamos tentar ler e alterar se o arquivo for uma Peça!
					if recurso is TeamPlayer:
						
						# Preenche a mochila com "nulls" baseado no limite da peça na memória RAM
						if recurso.slotsUpgrates.size() != recurso.quantosSlotes:
							recurso.slotsUpgrates.resize(recurso.quantosSlotes)
							
						# Salva no Banco de Dados
						pecas_db[recurso.id_unico] = recurso
						
			file = dir.get_next()
