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
	if CupManager.isFinal:

		# Aqui vai acabar o torneio. Tem que avisar que ganhou esse cup e voltar para o menu
		get_tree().change_scene_to_file("res://Componentes/TabButtons/tab_buttons_canvas_layer.tscn")
	else:
		CupManager.nextCompetitor()
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
