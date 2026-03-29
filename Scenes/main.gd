extends Node3D

enum ModoTiro { PUXAR, EMPURRAR, MODO_3 }
var modo_atual = ModoTiro.PUXAR

func _on_button_pressed() -> void:
	# Alterna entre os modos (por enquanto 0 e 1, o 2 deixaremos pronto)
	modo_atual = (modo_atual + 1) % 3 
	
	var texto_botao = ""
	match modo_atual:
		ModoTiro.PUXAR:
			texto_botao = "Modo: Puxar"
		ModoTiro.EMPURRAR:
			texto_botao = "Modo: Empurrar"
		ModoTiro.MODO_3:
			texto_botao = "Modo: Carregar"
			
	$CanvasLayer/Button.text = texto_botao
	
	# Avisa todas as peças do jogo qual é o novo modo
	get_tree().call_group("pecas", "set_modo_tiro", modo_atual)


func _on_button_puxar_pressed() -> void:
	_on_button_pressed()


func _on_botao_restart_pressed() -> void:
	get_tree().reload_current_scene()
	
