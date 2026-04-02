extends Node


@export var current_team = 1

@export var current_posse = 0
	
@export var colidiu = false

@export var peca_selecionada:Peca = null

@export var esperando_fisica = false

var pecas = null

var ball = null

func _ready():
	var r = randi_range(1,10)
	if r > 5:
		current_team = 1
	else:
		current_team = 2

	pecas = get_tree().get_nodes_in_group("pecas")
	ball = get_tree().get_nodes_in_group("ball")[0]

func _process(delta: float) -> void:
	for p in pecas:
		if !p.sleeping:
			esperando_fisica = true
			return
			
	if !ball.sleeping:
		esperando_fisica=true
		return
	esperando_fisica=false

func troca_time():
		if current_team == 1:
			current_team = 2
			current_posse=2
		else:
			current_team = 1
			current_posse=1

func reset_field():
	var pecas = get_tree().get_nodes_in_group("pecas")
	for p in pecas:
		p.position = p.initialPos
		p.sleeping = true
	var ball = get_tree().get_nodes_in_group("ball")[0]
	ball.sleeping = true
	ball.position = Vector3(0,0,0)
