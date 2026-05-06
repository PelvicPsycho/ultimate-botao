extends Resource
class_name Team

enum Rank {F,E,D,C,B,A,S,PLAYER}

@export_category("Infos do time")
@export var name: String = ""
@export var id: int
@export var rank: Rank
@export var cor: Color

@export_category("Elenco")
@export var mainSquad: Array[TeamPlayer]
@export var collectedSquad: Array[TeamPlayer]
