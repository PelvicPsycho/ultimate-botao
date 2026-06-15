extends TextureButton

var is_hovered: bool = false
var escala_original: Vector2 = Vector2(1, 1) # Será atualizado pelo MenuRadial

func _process(_delta: float) -> void:
	# Faz o Hover Sintético nela mesma
	var rect = Rect2(Vector2.ZERO, size)
	var mouse_em_cima = rect.has_point(get_local_mouse_position())
	
	if mouse_em_cima and not is_hovered:
		is_hovered = true
		_animar(1.2) # Cresce 20%
		
	elif not mouse_em_cima and is_hovered:
		is_hovered = false
		_animar(1.0) # Volta ao normal

func _animar(multiplicador: float) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", escala_original * multiplicador, 0.2)
