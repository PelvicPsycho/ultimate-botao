extends CanvasLayer

@onready var label_time = $Label_Time

@onready var label_placar = $Label_Placar

@export var goleira1:Node3D = null
@export var goleira2:Node3D = null

@export var pontos1 = 0
@export var pontos2 = 0

signal gol_de(team:int);

func _ready() -> void:
	label_placar.text = "0 x 0"
	pontos1=0
	pontos2 = 0
	goleira1.gol.connect(_on_gol_de,1)
	goleira2.gol.connect(_on_gol_de,2);

func _process(delta: float) -> void:
	label_time.text = "Team " +str(EquipeAtual.current_team)
	
	
	


func _on_gol_de(team: int) -> void:
	if team == 1:
		pontos1 = pontos1 + 1
		label_placar.text = str(pontos1) +" x " + str(pontos2)
	elif team == 2:
		pontos2 = pontos2+1
		label_placar.text = str(pontos1) +" x " + str(pontos2)
