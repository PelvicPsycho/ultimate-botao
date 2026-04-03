extends Resource
class_name Team

enum Rank {F,E,D,C,B,A,S}

@export_category("Infos do time")
@export var name: String = ""
@export var id: int
@export var ranque: Rank
@export var cor: Color

@export_category("Elenco")
@export var elenco: Array[TeamPlayer]
