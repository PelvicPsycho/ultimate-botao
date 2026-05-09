extends CanvasLayer

#Nodos
@onready var youWinLabel = $Control/Panel/VBoxContainer/VBoxContainer/YouWin
@onready var scoreLabel = $Control/Panel/VBoxContainer/VBoxContainer/Placar
@onready var championLabel = $"Control/Panel/VBoxContainer/VBoxContainer/Champion!"

func _ready():
	hide()

func _show(winner: String,  score: String, playerWin: bool):
	if GameState.isFinal and playerWin:
		championLabel.show()  
	else:
		championLabel.hide()
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
	GameState.nextCompetitor()
	get_tree().reload_current_scene()
