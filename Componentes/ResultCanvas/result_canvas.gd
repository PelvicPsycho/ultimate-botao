extends CanvasLayer

#Nodos
@onready var youWinLabel = $Control/Panel/VBoxContainer/VBoxContainer/YouWin
@onready var scoreLabel = $Control/Panel/VBoxContainer/VBoxContainer/Placar
@onready var championLabel = $"Control/Panel/VBoxContainer/VBoxContainer/Champion!"
@onready var cupLabel = $Control/Panel/VBoxContainer/VBoxContainer/CupLabel
@export var NextBtn: Button
@export var QuitBtn: Button

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

func _set_match_paused(value: bool) -> void:
	if get_tree() != null:
		get_tree().paused = value

func _show(winner: String,  score: String, playerWin: bool):
	if not PvPManager.isPvpMatch:
		if CupManager.isFinal and playerWin:
			championLabel.show()
			QuitBtn.visible = false
			NextBtn.text = "Retornar"
		else:
			championLabel.hide()
		cupLabel.text = CupManager.currentCup.cupName
		youWinLabel.text = winner + " ganhou!"
		scoreLabel.text = score
		if !playerWin:
			$Control/Panel/VBoxContainer/VBoxContainer2/Next.hide()
		
		else:
			$Control/Panel/VBoxContainer/VBoxContainer2/Next.show()
	else:
		championLabel.hide()
		$Control/Panel/VBoxContainer/VBoxContainer2/Next.hide()
		$Control/Panel/VBoxContainer/VBoxContainer2/Restart.show()
		cupLabel.text = "Friendly"
		youWinLabel.text = winner + " ganhou!"
		scoreLabel.text = score
	_set_match_paused(true)
	show()

func _on_quit_button_up():
	_set_match_paused(false)
	get_tree().change_scene_to_file("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")

func _on_restart_button_up():
	_set_match_paused(false)
	get_tree().reload_current_scene()

func _on_next_pressed() -> void:
	_set_match_paused(false)
	if CupManager.isFinal:
		# Torneio concluído! Desbloqueia o próximo rank e volta ao menu
		CupManager._desbloquear_proximo_torneio()
		get_tree().change_scene_to_file("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")
	else:
		CupManager.nextCompetitor()
		get_tree().reload_current_scene()
