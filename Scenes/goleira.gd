extends Node3D
class_name Goal

@export var team = 0

signal gol(team:int)

func _ready() -> void:
	if position.x < 0:
		team = 1
		
	else:
		team = 2
		

func _on_area_3d_body_entered(body: Node3D) -> void:
	print('body ' + str(body))
	if body.is_in_group('ball'):
		print('goal')
		if team == 1:
			emit_signal("gol",2)
		else:
			emit_signal("gol",1)
		
