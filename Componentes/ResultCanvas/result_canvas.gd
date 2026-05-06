extends CanvasLayer

#Nodos
@onready var youWinLabel = $Control/Panel/VBoxContainer/VBoxContainer/YouWin
@onready var scoreLabel = $Control/Panel/VBoxContainer/VBoxContainer/Placar

func _ready():
	hide()

func _show(winner: String,  score: String, playerWin: bool):
	youWinLabel.text = winner + " ganhou!"
	scoreLabel.text = score
	if !playerWin:
		$Control/Panel/VBoxContainer/VBoxContainer2/Next.hide()
		
	else:
		$Control/Panel/VBoxContainer/VBoxContainer2/Next.show()
	show()

func _on_quit_button_up():
	get_tree().quit()

func _on_restart_button_up():
	get_tree().reload_current_scene()

func _on_next_pressed() -> void:
	if GameState.matchesPlayed < GameState.followingCompetitors.size():
		GameState.nextCompetitor()
	else: 
		GameState.nextCup()
	get_tree().reload_current_scene()
