extends Resource
class_name Team

enum Rank {F,E,D,C,B,A,S,PLAYER}

@export_category("Infos do time")
@export var name: String = ""
@export var id: int
@export var ranque: Rank
@export var cor: Color
@export var emblem: Texture2D

@export_category("Elenco")
@export var mainSquad: Array[TeamPlayer]
@export var collectedSquad: Array[TeamPlayer]
@export var materialAtivo:ShaderMaterial
@export var materialInativo:ShaderMaterial
@export_category("Overlay do Shader")
@export_enum("Nenhum", "Textura 1", "Textura 2", "Textura 3") var overlay_escolhido: int = 0

@export var textura_overlay_1: Texture2D
@export var textura_overlay_2: Texture2D
@export var textura_overlay_3: Texture2D


func get_overlay_texture() -> Texture2D:
	match overlay_escolhido:
		1: return textura_overlay_1
		2: return textura_overlay_2
		3: return textura_overlay_3
		_: return null
