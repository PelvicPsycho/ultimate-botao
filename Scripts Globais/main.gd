extends Node3D

enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }
var modo_atual = ModoTiro.PUXAR


func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
