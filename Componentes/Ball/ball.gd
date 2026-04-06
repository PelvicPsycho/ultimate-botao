extends RigidBody3D
class_name Ball

var lastTouch: Player

func _on_body_entered(body):
	if body.is_in_group("Players") or body is Player:
		print('Tocou em ' + str(body))
		lastTouch = body
