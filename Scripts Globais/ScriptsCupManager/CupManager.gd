extends Node

@onready var currentCup: Cup
@onready var cupList: Array[Cup] = [preload("res://Recursos/Cups/FCup.tres"), 
preload("res://Recursos/Cups/ECup.tres"), 
preload("res://Recursos/Cups/DCup.tres"), 
preload("res://Recursos/Cups/CCup.tres"), 
preload("res://Recursos/Cups/BCup.tres"), 
preload("res://Recursos/Cups/ACup.tres"), 
preload("res://Recursos/Cups/SCup.tres")]
@onready var cupsPlayed: int = 0

@onready var myTeam: Team = preload("res://Recursos/Teams/Other Teams/MyTeam/MyTeam.tres")
@onready var matchesPlayed: int = 0

@onready var currentCompetitor: Team
var followingCompetitors: Array[Team]
var isFinal: bool = false

func _ready() -> void:
	var all_teams: Array[Team] = [myTeam]
	for cup in cupList:
		for team in cup.teamPool:
			if team not in all_teams:
				all_teams.append(team)
		for team in cup.nextTeamPool:
			if team not in all_teams:
				all_teams.append(team)
	for team in all_teams:
		for player in team.mainSquad:
			player.time = team
		for player in team.collectedSquad:
			player.time = team
	
	# Sincroniza o mainSquad do time do jogador com o save carregado
	_sync_main_squad_from_gamestate()

func _sync_main_squad_from_gamestate() -> void:
	if GameState.jogadores.is_empty():
		return
	var num_titulares = mini(myTeam.mainSquad.size(), GameState.jogadores.size())
	for i in range(num_titulares):
		myTeam.mainSquad[i] = GameState.jogadores[i]
		if myTeam.mainSquad[i] != null:
			myTeam.mainSquad[i].time = myTeam
	
	# Preenche o collectedSquad com as peças restantes (reservas)
	myTeam.collectedSquad.clear()
	for i in range(num_titulares, GameState.jogadores.size()):
		var peca_reserva = GameState.jogadores[i]
		myTeam.collectedSquad.append(peca_reserva)
		if peca_reserva != null:
			peca_reserva.time = myTeam
	
	#print("✔ mainSquad: %d titulares | collectedSquad: %d reservas" % [num_titulares, myTeam.collectedSquad.size()])
	#
	#print("── Titulares ──")
	#for i in range(myTeam.mainSquad.size()):
		#var p = myTeam.mainSquad[i]
		#print("  %d. %s" % [i + 1, p.nome if p else "VAZIO"])
	#
	#print("── Reservas ──")
	#if myTeam.collectedSquad.is_empty():
		#print("  (nenhuma)")
	#else:
		#for i in range(myTeam.collectedSquad.size()):
			#print("  %d. %s" % [i + 1, myTeam.collectedSquad[i].nome])

## Chamado quando o jogador completa um torneio (todas as partidas).
## Desbloqueia o próximo torneio mais difícil (rank imediatamente inferior).
func _desbloquear_proximo_torneio() -> void:
	var rank_atual: int = currentCup.cupRank
	var proximo_rank: int = rank_atual - 1  # Mais difícil = número menor no enum
	if proximo_rank < 0:
		return  # Já venceu o torneio S (mais difícil), nada a desbloquear
	
	# Procura o cup com o rank desejado na cupList
	for cup in cupList:
		if cup.cupRank == proximo_rank:
			var nome: String = cup.cupName
			if nome not in GameState.torneios_desbloqueados:
				GameState.torneios_desbloqueados.append(nome)
				print("🏆 Torneio desbloqueado: ", nome)
				SaveManager.save_game()
			return

func newRun(): #PARA DELETAR
	matchesPlayed = 0
	playCup(0)
	currentCompetitor = followingCompetitors[0]
	#print("Playing now: ", myTeam.name, " Vs ", currentCompetitor.name)

func playCup(index: int):
	currentCup = cupList[index]
	#print("Playing cup: ", currentCup)
	pickCompetitors()

func nextCup():
	# Desbloqueia o próximo torneio mais difícil antes de avançar
	_desbloquear_proximo_torneio()
	
	isFinal = false
	cupsPlayed+=1
	matchesPlayed = 0
	if cupsPlayed < cupList.size():
		currentCup = cupList[cupsPlayed]
	else:
		cupsPlayed = 0
	pickCompetitors()
	currentCompetitor = followingCompetitors[0]

func nextCompetitor():
	print(CupManager.myTeam.collectedSquad)
	matchesPlayed+=1
	if matchesPlayed < currentCup.numMatches:
		currentCompetitor = followingCompetitors[matchesPlayed]
		if matchesPlayed == currentCup.numMatches-1:
			isFinal = true
			#print("FINAL OF ", currentCup.cupName)
		#print("Playing now: ", myTeam.name, " Vs ", currentCompetitor.name)
	else: 
		nextCup()
	#saveGame()

func pickCompetitors():
	var numCompetitors = currentCup.numMatches
	followingCompetitors.clear()
	var pool: Array[Team] = currentCup.teamPool.duplicate()
	pool.shuffle()
	for team in pool:
		if followingCompetitors.size() >= numCompetitors:
			break
		if team != myTeam:
			followingCompetitors.append(team)
	#print("Following matches: ", followingCompetitors)

func saveGame():
	#print("matches played: ", matchesPlayed)
	#print("current cup:", currentCup.cupName)
	pass

func loadGame():
	pass

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		#saveGame()
		get_tree().quit()

# Nova função para iniciar o torneio escolhido pelo jogador
func iniciar_torneio_selecionado(cup_escolhido: Cup) -> void:
	# 1. Descobre qual é o índice (0 a 6) da copa escolhida na sua lista oficial
	var index = cupList.find(cup_escolhido)
	if index == -1:
		printerr("Erro: O torneio selecionado não existe na cupList do CupManager!")
		return

	# 2. Configura a nova Run usando a lógica que você já tinha
	matchesPlayed = 0
	playCup(index)
	currentCompetitor = followingCompetitors[0]
	isFinal = false
	
	print("Iniciando torneio: ", currentCup.cupName, " | Primeira partida: ", myTeam.name, " VS ", currentCompetitor.name)

	# 3. DELEGAÇÃO: Atualiza a memória global e salva o jogo aqui!
	GameState.ultimo_torneio_jogado = currentCup.cupName
	SaveManager.save_game()
