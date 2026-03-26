extends Node

@export var current_team = 1

func _ready():
	var r = randi_range(1,10)
	if r > 5:
		current_team = 1
	else:
		current_team = 2
