extends RigidBody3D

class_name ball

func _ready():
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("pecas"):
		print('entrou em ' + str(body))
		if body.team == Peca.Team.Team1:
			EquipeAtual.colidiu = true
			EquipeAtual.current_team=1
		elif body.team == Peca.Team.Team2:
			EquipeAtual.colidiu = true
			EquipeAtual.current_team=2
	else:
		print('erro')
