extends Node2D

signal carta_clicada(carta)

var is_open: bool = false
var _pa_atual: int = 0
var _animating := false
var _cartas: Array = []
var _outline_shader := preload("res://2D Changes/Shader_2d/outline2d.gdshader")

@onready var pa_slots_container = $PADots
@onready var buttons: Array[Area2D] = [
	$BtnCentro, $BtnCima, $BtnDireita, $BtnBaixo, $BtnEsquerda
]

func _ready() -> void:
	for btn in buttons:
		btn.input_pickable = true
		if btn.get_child_count() == 0:
			push_warning("Botão " + btn.name + " está sem colisor!")
		
		btn.input_event.connect(_on_btn_click.bind(btn))
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		btn.visible = false
		btn.scale = Vector2.ZERO
	hide()

func abrir() -> void:
	if is_open or _animating: return
	is_open = true
	_animating = true
	show()
	
	# Animação apenas para os BOTÕES (Escala)
	for i in range(buttons.size()):
		if buttons[i] != null and buttons[i].visible:
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var tweener = tween.tween_property(buttons[i], "scale", Vector2.ONE, 0.3)
			if tweener:
				tweener.set_delay(i * 0.05)
	
	
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
	
	await get_tree().create_timer(0.3).timeout
	hide()
	_animating = false

func definir_pa(pa_atual: int, max_pa: int = 8) -> void:
	_pa_atual = pa_atual
	var slots = pa_slots_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		slot.visible = (i < max_pa)
		
		if slot.visible:
			var dot = slot.get_node_or_null("Dot")
			if dot != null:
				
				dot.visible = (i < pa_atual)
				
			
	
	print("DEBUG: PA Atualizado. Max: ", max_pa, " | Atual: ", pa_atual)

func definir_cartas(cartas: Array, pa_atual: int = 0, max_pa: int = 8) -> void:
	_cartas = cartas
	definir_pa(pa_atual, max_pa)
	
	for btn in buttons:
		btn.visible = false
	
	for i in range(min(cartas.size(), buttons.size())):
		var btn = buttons[i]
		var carta = cartas[i]
		btn.visible = true
		btn.set_meta("carta", carta)
		
		
		var icone = btn.get_node_or_null("Art")
		if icone:
			
			var tex = carta.get("arte") if "arte" in carta else carta.get("Arte")
			if tex:
				icone.texture = tex
				icone.visible = true
				icone.modulate.a = 1.0 
		
	
			
		var custo = carta.custo_energia if "custo_energia" in carta else 1
		btn.modulate = Color(1, 1, 1, 1) if _pa_atual >= custo else Color(0.3, 0.3, 0.3, 0.2)
	
	abrir()

func _on_btn_hover(btn: Area2D) -> void:
	if _animating or not btn.visible: return
	var fundo = btn.get_node_or_null("Sprite2D")
	
	if fundo and fundo is Sprite2D:
		if not fundo.material:
			var mat = ShaderMaterial.new()
			mat.shader = _outline_shader
			
			mat.set_shader_parameter("outline_color", Color(0, 0.5, 1.0,0.6)) 
			mat.set_shader_parameter("outline_width", 2.0)
			fundo.material = mat
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)
	
	
	tween.tween_property(btn, "modulate:a", 1, 0.15)
	
	print("DEBUG: Shader de outline aplicado ao Sprite2D com alpha independente.")

func _on_btn_unhover(btn: Area2D) -> void:
	if _animating or not btn.visible: return
	
	
	var fundo = btn.get_node_or_null("Sprite2D")
	if fundo:
		fundo.material = null
		
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)
	
	if btn.has_meta("carta"):
		var carta = btn.get_meta("carta")
		var custo = carta.custo_energia if "custo_energia" in carta else 1
		
		var alpha_alvo = 1 if _pa_atual >= custo else 0.3
		tween.tween_property(btn, "modulate:a", alpha_alvo, 0.12)
	

func _on_btn_click(_viewport: Node, event: InputEvent, _shape_idx: int, btn: Area2D) -> void:
	if _animating: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if btn.has_meta("carta"):
			emit_signal("carta_clicada", btn.get_meta("carta"))
			fechar()
