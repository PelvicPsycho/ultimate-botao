extends Control

signal selection_changed(card, is_selected: bool)

var team: Team

@onready var emblemTexture: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/Panel/MarginContainer/TextureRect
@onready var teamNameLabel: Label = $PanelContainer/MarginContainer/VBoxContainer/Label
@onready var teamButton: Button = $PanelContainer

func _ready() -> void:
	if not teamButton.toggled.is_connected(_on_team_button_toggled):
		teamButton.toggled.connect(_on_team_button_toggled)
	_refresh_ui()


func set_team(new_team: Team) -> void:
	team = new_team
	if is_node_ready():
		_refresh_ui()


func _refresh_ui() -> void:
	if team == null:
		return

	emblemTexture.texture = team.emblem
	teamNameLabel.text = team.name


func set_interactable(enabled: bool) -> void:
	teamButton.disabled = not enabled


func set_selected(selected: bool) -> void:
	teamButton.set_pressed_no_signal(selected)


func is_selected() -> bool:
	return teamButton.button_pressed


func _on_team_button_toggled(is_selected: bool) -> void:
	emit_signal("selection_changed", self, is_selected)
