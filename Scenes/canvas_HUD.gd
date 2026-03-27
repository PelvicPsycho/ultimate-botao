extends CanvasLayer

@onready var label_time = $Label_Time


func _process(delta: float) -> void:
	label_time.text = "Team " +str(EquipeAtual.current_team)
