extends Resource
class_name Team

enum Rank {F,E,D,C,B,A,S,PLAYER}

#@export_category("Infos do time")
@export var name: String = ""
@export var id: int
@export var ranque: Rank
@export var cor: Color
@export var emblem: Texture2D = preload("res://Recursos/Teams/Generic Emblem/generic.png")

#@export_category("Elenco")
@export var mainSquad: Array[TeamPlayer]
@export var collectedSquad: Array[TeamPlayer]
@export var materialAtivo:ShaderMaterial
@export var materialInativo:ShaderMaterial
@export_category("Overlay do Shader")
@export_enum("Nenhum", "Textura 1", "Textura 2", "Textura 3", "Textura 4") var overlay_escolhido: int = 0

## Texturas de overlay para a peça na partida (vista de cima)
@export var textura_overlay_1: Texture2D = preload("res://2D Changes/Components/Pecas/padroes/Padrao1.png")
@export var textura_overlay_2: Texture2D = preload("res://2D Changes/Components/Pecas/padroes/Padrao2.png")
@export var textura_overlay_3: Texture2D = preload("res://2D Changes/Components/Pecas/padroes/Padrao3.png")
@export var textura_overlay_4: Texture2D = preload("res://2D Changes/Components/Pecas/padroes/Padrao4.png")

## Texturas de overlay para a peça nos menus (vista em ângulo de 30°)
@export var textura_overlay_menu_1: Texture2D = preload("res://2D Changes/Components/Pecas/padroes_peca_de_frente/Padrao1.png")
@export var textura_overlay_menu_2: Texture2D = preload("res://2D Changes/Components/Pecas/padroes_peca_de_frente/Padrao2.png")
@export var textura_overlay_menu_3: Texture2D = preload("res://2D Changes/Components/Pecas/padroes_peca_de_frente/Padrao3.png")
@export var textura_overlay_menu_4: Texture2D = preload("res://2D Changes/Components/Pecas/padroes_peca_de_frente/Padrao4.png")

func get_overlay_texture() -> Texture2D:
	match overlay_escolhido:
		1: return textura_overlay_1
		2: return textura_overlay_2
		3: return textura_overlay_3
		4: return textura_overlay_4
		_: return null

func get_overlay_texture_menu() -> Texture2D:
	match overlay_escolhido:
		1: return textura_overlay_menu_1
		2: return textura_overlay_menu_2
		3: return textura_overlay_menu_3
		4: return textura_overlay_menu_4
		_: return null
