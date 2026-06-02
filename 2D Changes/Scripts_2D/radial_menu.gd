extends Node2D

signal carta_clicada(carta)

var is_open: bool = false
var _pa_atual: int = 0
var _pa_anterior: int = 0
var _animating := false
var _cartas: Array = []
var _outline_shader := preload("res://2D Changes/Shader_2d/outline2d.gdshader")

@onready var buttons: Array[Area2D] = [
	$BtnCentro, $BtnCima, $BtnDireita, $BtnBaixo, $BtnEsquerda
]
@onready var pa_dots: Array[Sprite2D] = [
	$PADots/PADot1, $PADots/PADot2, $PADots/PADot3, $PADots/PADot4,
	$PADots/PADot5, $PADots/PADot6, $PADots/PADot7, $PADots/PADot8
]

func _ready() -> void:
	for btn in buttons:
		btn.input_pickable = true
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 32.0
		shape.shape = circle
		btn.add_child(shape)
		btn.input_event.connect(_on_btn_click.bind(btn))
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		btn.visible = false
		btn.scale = Vector2.ZERO
	
	for dot in pa_dots:
		dot.scale = Vector2.ZERO
		dot.modulate = Color(1, 1, 1, 0)
	
	hide()



func abrir() -> void:
	if is_open or _animating: return
	is_open = true
	_animating = true
	show()
	
	for i in range(buttons.size()):
		if buttons[i].visible:
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(buttons[i], "scale", Vector2.ONE, 0.3).set_delay(i * 0.05)
	

	for i in range(pa_dots.size()):
		var delay = 0.3 + i * 0.04
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(pa_dots[i], "scale", Vector2.ONE, 0.25).set_delay(delay)
		tween.parallel().tween_property(pa_dots[i], "modulate", Color.WHITE if i < _pa_atual else Color(0.3, 0.3, 0.3, 0.4), 0.2).set_delay(delay)
	
	await get_tree().create_timer(0.6 + pa_dots.size() * 0.04).timeout
	_animating = false

func fechar() -> void:
	if not is_open or _animating: return
	is_open = false
	_animating = true
	

	for i in range(buttons.size()):
		if buttons[i].visible:
			var delay = (buttons.size() - i) * 0.03
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(buttons[i], "scale", Vector2.ZERO, 0.2).set_delay(delay)
	

	for i in range(pa_dots.size()):
		var delay = (pa_dots.size() - i) * 0.02
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(pa_dots[i], "scale", Vector2.ZERO, 0.15).set_delay(delay)
		tween.parallel().tween_property(pa_dots[i], "modulate", Color(1, 1, 1, 0), 0.12).set_delay(delay)
	
	await get_tree().create_timer(0.3 + pa_dots.size() * 0.03).timeout
	hide()
	_animating = false

func definir_cartas(cartas: Array, pa_atual: int = 999) -> void:
	_cartas = cartas
	_pa_atual = pa_atual
	_pa_anterior = pa_atual
	
	for btn in buttons:
		btn.visible = false
		btn.remove_meta("carta")
	
	if cartas.is_empty():
		return
	
	for i in range(min(cartas.size(), buttons.size())):
		var btn = buttons[i]
		var carta = cartas[i]
		btn.visible = true
		btn.scale = Vector2.ZERO
		btn.set_meta("carta", carta)
		
		var icone = btn.get_node_or_null("Art")
		if icone:
			var tex = carta.get("arte") if "arte" in carta else \
					  carta.get("Arte") if "Arte" in carta else null
			icone.texture = tex
		
		var custo = carta.custo_energia if "custo_energia" in carta else 1
		btn.modulate = Color.WHITE if _pa_atual >= custo else Color(0.4, 0.4, 0.4, 0.6)
	
	abrir()

func definir_pa(pa_atual: int, max_pa: int = 8) -> void:
	_pa_anterior = _pa_atual
	_pa_atual = pa_atual
	_atualizar_visuais()
	_animar_pa_dots()  

func _atualizar_visuais() -> void:
	for i in range(min(_cartas.size(), buttons.size())):
		var btn = buttons[i]
		var carta = _cartas[i]
		var custo = carta.custo_energia if "custo_energia" in carta else 1
		btn.modulate = Color.WHITE if _pa_atual >= custo else Color(0.4, 0.4, 0.4, 0.6)


func _animar_pa_dots() -> void:
	for i in range(pa_dots.size()):
		var ativo_antes = i < _pa_anterior
		var ativo_agora = i < _pa_atual
		
		if ativo_antes == ativo_agora:
			continue  # não mudou, pula
		
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		if ativo_agora:
		
			pa_dots[i].scale = Vector2.ZERO
			pa_dots[i].modulate = Color(0.3, 0.3, 0.3, 0.4)
			tween.tween_property(pa_dots[i], "scale", Vector2(1.3, 1.3), 0.15)
			tween.tween_property(pa_dots[i], "scale", Vector2.ONE, 0.1)
			tween.parallel().tween_property(pa_dots[i], "modulate", Color.WHITE, 0.2)
		else:
			
			tween.tween_property(pa_dots[i], "modulate", Color(0.3, 0.3, 0.3, 0.4), 0.15)
			tween.parallel().tween_property(pa_dots[i], "scale", Vector2(0.5, 0.5), 0.12)

func _on_btn_click(_viewport: Node, event: InputEvent, _shape_idx: int, btn: Area2D) -> void:

	if _animating:
		_animating = false
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if btn.has_meta("carta"):
			emit_signal("carta_clicada", btn.get_meta("carta"))
			fechar()
func _on_btn_hover(btn: Area2D) -> void:
	if _animating or not btn.visible: return
	var sprite = btn.get_node_or_null("Sprite2D")
	if sprite and not sprite.material:
		var mat = ShaderMaterial.new()
		mat.shader = _outline_shader
		mat.set_shader_parameter("outline_color", Color(0, 0.0, 0.8))
		mat.set_shader_parameter("outline_width", 3.0)
		sprite.material = mat
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15)

	tween.parallel().tween_property(btn, "modulate", Color(1.0, 0.95, 0.75), 0.15)

func _on_btn_unhover(btn: Area2D) -> void:
	if _animating or not btn.visible: return
	var sprite = btn.get_node_or_null("Sprite2D")
	if sprite:
		sprite.material = null
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.12)
	
	if btn.has_meta("carta"):
		var carta = btn.get_meta("carta")
		var custo = carta.custo_energia if "custo_energia" in carta else 1
		tween.parallel().tween_property(btn, "modulate", Color.WHITE if _pa_atual >= custo else Color(0.4, 0.4, 0.4, 0.6), 0.12)
		
func _atualizar_pa_dots() -> void:
	for i in range(pa_dots.size()):
		pa_dots[i].modulate = Color.WHITE if i < _pa_atual else Color(0.3, 0.3, 0.3, 0.4)
