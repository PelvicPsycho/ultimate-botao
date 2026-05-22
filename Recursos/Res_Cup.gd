extends Resource
class_name Cup

enum CUP_RANK{S,A,B,C,D,E,F}

@export var cupName: String = ""
@export var cupRank: CUP_RANK
@export var numMatches: int = 3
@export var teamPool: Array[Team]
@export var nextTeamPool: Array[Team]
