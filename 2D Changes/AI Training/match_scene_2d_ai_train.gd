extends MatchState_Tutorial
class_name MatchState_Training

@onready var SpawnPoints: Array = $SpawnPoints.get_children()
@onready var player = $PhysicsController/HomeTeam/HomeTeam_P5
@onready var ball = $PhysicsController/Balls/Ball2D_Tutorial

var goalsScored = 0

signal goalScored

func onGoal(isHome: bool) -> void:
	goalsScored += 1
	goalScored.emit()
	print(goalsScored)

func pickPlayerSpawn():
	var pickedIndex = randi_range(0, SpawnPoints.size()-1)
	var pickedSP = SpawnPoints[pickedIndex]
	player.global_position = pickedSP.global_position
	
func pickBallSpawn():
	var pickedIndex = randi_range(0, SpawnPoints.size()-1)
	var pickedSP = SpawnPoints[pickedIndex]
	ball.global_position = pickedSP.global_position
	ball.Set_Current_Velocity(Vector2.ZERO)
