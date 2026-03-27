extends RigidBody3D

class_name ball


func _on_body_entered(body: Node) -> void:
	print('entrou em ' + str(body))
