extends Node2D
class_name Goal2D

enum TeamSide {HOME, AWAY}

@onready var GoalExplosion = $GoalExplosion

@export var team: TeamSide
@export var expulsar_forca_base: float = 3.0

signal gol(isHome: bool) #True = gol Home, False = gol Away (a principio)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("body_entered goal = ", body.name)
	if body.is_in_group('Balls'):
		print("body_entered goal is a ball")
		gol.emit(true if team == TeamSide.HOME else false)
		GoalExplosion.emitExplosion(false if team == TeamSide.HOME else true)
