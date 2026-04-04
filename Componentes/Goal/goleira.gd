extends Node3D
class_name Goal

enum TeamSide {HOME, AWAY}
@export var team: TeamSide

signal gol(isHome: bool) #True = gol Home, False = gol Away (a principio)

func _on_area_3d_body_entered(body: Node3D) -> void:
	print('body entrou no gol: ' + str(body))
	if body.is_in_group('Balls'):
		print('gol de: ' + str(true if team == TeamSide.HOME else false))
		gol.emit(true if team == TeamSide.HOME else false)
