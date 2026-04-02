extends Node3D
class_name Goal

enum TeamSide {HOME, AWAY}
@export var team: TeamSide

signal gol(isHome: bool)

func _on_area_3d_body_entered(body: Node3D) -> void:
	print('body ' + str(body))
	if body.is_in_group('ball'):
		print('goal')
		gol.emit(true if team == TeamSide.HOME else false)
