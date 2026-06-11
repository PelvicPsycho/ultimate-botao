extends Control

@export var teams: Array[Team] = []
@export var team_card_scene: PackedScene = preload("res://Componentes/TabButtons/PvP Team Selection/TeamCard.tscn")
@export var match_scene: PackedScene = preload("res://Componentes/Simulation_AI/Scenes/MatchScene2D_AI.tscn")

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer
@onready var next_button: Button = $MarginContainer/VBoxContainer/Button

var team_cards: Array[Node] = []
var selected_team_cards: Array[Node] = []


func _ready() -> void:
	if next_button != null and not next_button.pressed.is_connected(_on_button_pressed):
		next_button.pressed.connect(_on_button_pressed)

	spawn_team_cards()
	_update_selection_constraints()


func spawn_team_cards() -> void:
	if grid_container == null:
		push_warning("GridContainer not found in TeamSelection scene.")
		return

	if team_card_scene == null:
		push_warning("Team card scene is not assigned.")
		return

	for child in grid_container.get_children():
		child.queue_free()

	team_cards.clear()
	selected_team_cards.clear()

	for team in teams:
		if team == null:
			continue

		var team_card := team_card_scene.instantiate()
		if team_card == null:
			continue

		if team_card.has_method("set_team"):
			team_card.set_team(team)
		elif "team" in team_card:
			team_card.team = team

		if team_card.has_signal("selection_changed"):
			team_card.selection_changed.connect(_on_team_card_selection_changed)

		grid_container.add_child(team_card)
		team_cards.append(team_card)

	_update_selection_constraints()

func _on_button_pressed():
	if selected_team_cards.size() != 2:
		return
		
	if match_scene == null:
		push_warning("Match scene is not assigned.")
		return
		
	PvPManager.teams = [selected_team_cards[0].team, selected_team_cards[1].team]
	PvPManager.isPvpMatch = true
	get_tree().change_scene_to_packed(match_scene)


func _on_team_card_selection_changed(card: Node, is_selected: bool) -> void:
	if is_selected:
		if selected_team_cards.has(card):
			_update_selection_constraints()
			return

		if selected_team_cards.size() >= 2:
			if card.has_method("set_selected"):
				card.set_selected(false)
			return

		selected_team_cards.append(card)
	else:
		selected_team_cards.erase(card)

	_update_selection_constraints()


func _update_selection_constraints() -> void:
	var has_two_selected := selected_team_cards.size() >= 2

	for card in team_cards:
		if card == null:
			continue

		var keep_enabled := (not has_two_selected) or selected_team_cards.has(card)
		if card.has_method("set_interactable"):
			card.set_interactable(keep_enabled)

	if next_button != null:
		next_button.disabled = selected_team_cards.size() != 2
