extends CanvasLayer

#Nodos
@onready var youWinLabel = $Control/Panel/VBoxContainer/VBoxContainer/YouWin
@onready var scoreLabel = $Control/Panel/VBoxContainer/VBoxContainer/Placar

func _ready():
	hide()

func _show(winner: String,  score: String):
	youWinLabel.text = winner + " ganhou!"
	scoreLabel.text = score
	show()

func _on_quit_button_up():
	get_tree().quit()

func _on_restart_button_up():
	get_tree().reload_current_scene()
