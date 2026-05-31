extends CanvasLayer

## Botão de debug: força a IA a executar uma jogada para o time do turno atual.
## Adicione esta cena ao MatchScene2D_AI e aponte o NodePath do IA_Controller.

@export var ia_controller: IA_Controller

func _on_button_pressed() -> void:
	print ("TOCA IA")
	if not ia_controller:
		push_warning("ForceIAButton: IA_Controller não está definido!")
		return
	
	# O MatchState já mantém current_TeamSide sincronizado com o turno atual.
	# Basta liberar a IA para rodar — no próximo _process ela dispara.
	ia_controller.AI_CanRun = true
