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

@onready var myTeam: Team = preload("res://Recursos/Teams/My Team/MyTeam.tres")
@onready var matchesPlayed: int = 0

@onready var currentCompetitor: Team
var followingCompetitors: Array[Team]

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

func newRun():
	matchesPlayed = 0
	playCup(0)
	currentCompetitor = followingCompetitors[0]
	print("Playing now: ", myTeam.name, " Vs ", currentCompetitor.name)

func playCup(index: int):
	currentCup = cupList[index]
	print("Playing cup: ", currentCup)
	pickCompetitors()

func nextCup():
	cupsPlayed+=1
	currentCup = cupList[cupsPlayed]
	pickCompetitors()

func nextCompetitor():
	matchesPlayed+=1
	currentCompetitor = followingCompetitors[matchesPlayed]
	saveGame()

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
	print("Following matches: ", followingCompetitors)

func saveGame():
	pass

func loadGame():
	pass

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		saveGame()
		get_tree().quit()
