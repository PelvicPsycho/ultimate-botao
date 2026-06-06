extends Node2D
class_name Goal2D_Simulation

enum TeamSide {HOME, AWAY}
@export var team: TeamSide

@export var GoalArea: CollisionShape2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('Balls'):
		print("body_entered goal is a ball - Simulation")

func _on_near_miss_area_body_entered(body):
	if body.is_in_group('Balls'):
		print("ball entered goal miss area - Simulation")
