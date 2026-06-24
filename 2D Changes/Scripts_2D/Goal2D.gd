extends Node2D
class_name Goal2D

enum TeamSide {HOME, AWAY}

@onready var GoalExplosion = $GoalExplosion

@export var team: TeamSide
@export var expulsar_forca_base: float = 3.0

@export var audio_quase_gol: AudioStream
var cooldown_quase_gol: bool = false

signal gol(isHome: bool) #True = gol Home, False = gol Away (a principio)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("body_entered goal = ", body.name)
	if body.is_in_group('Balls'):
		print ("quase gol body ")
		print("body_entered goal is a ball")
		gol.emit(true if team == TeamSide.HOME else false)
		GoalExplosion.emitExplosion(false if team == TeamSide.HOME else true)

func _on_near_miss_area_body_entered(body):
	if cooldown_quase_gol == false:
		if body.is_in_group('Balls'):
			cooldown_quase_gol = true
			print ("quase gol miss ", self)
			SoundMaster.play_sfx(audio_quase_gol)
			get_tree().create_timer(15.0).timeout.connect(func(): cooldown_quase_gol = false)
