extends CanvasLayer

@onready var winResultScene = $Control/WinResult
@onready var defeatResultScene = $Control/DefeatResult

func _ready():
	#process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

func _set_match_paused(value: bool) -> void:
	if get_tree() != null:
		get_tree().paused = value

func _show(score: String, playerWin: bool, homeTeamColor: Color, awayTeamColor: Color):
	if !playerWin:
		winResultScene.hide()
		defeatResultScene.show()
		defeatResultScene.setScore(score.split("X")[0], score.split("X")[1])
		$Control/DefeatResult.change_Score_background_TextureRect_Colors(homeTeamColor, awayTeamColor)
	else:
		winResultScene.show()
		defeatResultScene.hide()
		winResultScene.setScore(score.split("X")[0], score.split("X")[1])
		$Control/WinResult.change_Score_background_TextureRect_Colors(homeTeamColor, awayTeamColor)
	#_set_match_paused(true)
	show()
