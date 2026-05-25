extends CanvasLayer

#Nodos
@onready var youWinLabel = $Control/Panel/VBoxContainer/VBoxContainer/YouWin
@onready var scoreLabel = $Control/Panel/VBoxContainer/VBoxContainer/Placar
@onready var championLabel = $"Control/Panel/VBoxContainer/VBoxContainer/Champion!"

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

func _set_match_paused(value: bool) -> void:
	if get_tree() != null:
		get_tree().paused = value

func _show(winner: String,  score: String, playerWin: bool):
	if CupManager.isFinal and playerWin:
		championLabel.show()  
	else:
		championLabel.hide()
	youWinLabel.text = winner + " ganhou!"
	scoreLabel.text = score
	if !playerWin:
		$Control/Panel/VBoxContainer/VBoxContainer2/Next.hide()
		
	else:
		$Control/Panel/VBoxContainer/VBoxContainer2/Next.show()
	_set_match_paused(true)
	show()

func _on_quit_button_up():
	_set_match_paused(false)
	get_tree().quit()

func _on_restart_button_up():
	_set_match_paused(false)
	get_tree().reload_current_scene()

func _on_next_pressed() -> void:
	_set_match_paused(false)
	CupManager.nextCompetitor()
	#pickReward()
	get_tree().reload_current_scene()

func pickReward():
	var opposingTeam = CupManager.currentCompetitor
	var currentTeam = CupManager.myTeam
	var reward: TeamPlayer
	while true:
		reward = opposingTeam.mainSquad.pick_random()
		if reward not in currentTeam.collectedSquad or reward not in currentTeam.mainSquad:
			currentTeam.collectedSquad.append(reward)
			print("VOCE GANHOU: ", reward)
			return;
