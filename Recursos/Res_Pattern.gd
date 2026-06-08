extends Resource
class_name Padrao

@export var name: String = ""

@export_category("Jogadores")
@export var jogador_basic_min_force := 100.0
@export var jogador_basic_max_force := 1000.0
@export var jogador_basic_mass := 5.0
@export var jogador_basic_friction := 0.98
@export var jogador_basic_scale := 1.0

@export_category("Bola")
@export var bola_basic_min_force := 100.0
@export var bola_basic_max_force := 1000.0
@export var bola_basic_mass := 5.0
@export var bola_basic_friction := 0.98
@export var bola_basic_scale := 1.0
