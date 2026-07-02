extends Node
@export var imagem_clique: Texture2D = preload("res://Recursos/2D_Art/Cursor/curosr-clique.png")
@export var imagem_normal: Texture2D = preload("res://Recursos/2D_Art/Cursor/curosr-normal.png")
@export var ponto_de_clique: Vector2 = Vector2(0, 0)

func _ready() -> void:
# Assim que o jogo começa, aplicamos o cursor normal.
# Input.CURSOR_ARROW é o estado padrão do rato.
	Input.set_custom_mouse_cursor(imagem_normal, Input.CURSOR_ARROW, ponto_de_clique)

func _input(event: InputEvent) -> void:
# Verificamos se o evento foi feito com um botão do rato
	if event is InputEventMouseButton:
# Verificamos se foi o botão esquerdo
		if event.button_index == MOUSE_BUTTON_LEFT:
# Se o botão acabou de ser pressionado, trocamos para a imagem do dedo dobrado
			if event.pressed:
				Input.set_custom_mouse_cursor(imagem_clique, Input.CURSOR_ARROW, ponto_de_clique)
# Se o botão foi solto, voltamos para a imagem normal
			else:
				Input.set_custom_mouse_cursor(imagem_normal, Input.CURSOR_ARROW, ponto_de_clique)
