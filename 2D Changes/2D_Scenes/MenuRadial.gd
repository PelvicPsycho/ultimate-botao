extends Node2D

signal carta_clicada(carta)

@export var radius: float =50
@export var open_duration: float = 0.2
@export var button_scale := Vector2(1.3, 1.3)
@export var pa_cheia_texture: Texture2D
@export var pa_vazia_texture: Texture2D
@export var max_pa: int = 8
@export var raio_x_multiplier: float = 2.0 
@export var raio_y_multiplier: float = 1
var buttons: Array[Area2D] = []
var is_open: bool = false
var _pa_atual: int = 0
var _pa_icons: Array[Sprite2D] = []

func _ready() -> void:
	hide()
	_criar_grid_pa()

func abrir() -> void:
	if is_open:
		return
	is_open = true
	show()
	_open_animation()

func fechar() -> void:
	if not is_open:
		return
	is_open = false
	_close_animation()

func definir_cartas(cartas: Array, pa_atual: int = 999) -> void:
	_destroy_buttons()
	_pa_atual = pa_atual
	_atualizar_pa()
	
	if cartas.is_empty():
		return
	
	var total = cartas.size()
	var posicoes_laterais = int(ceil((total - 1) / 2.0))
	var step = deg_to_rad(28.0)  # ângulo fixo entre botões adjacentes
	for i in range(total):
		var carta = cartas[i]
		var btn = $ButtonModel.duplicate()
		btn.visible = true
		btn.scale = button_scale
		
		var col = btn.get_node("CollisionShape2D")
		col.disabled = false
		add_child(btn)
		
		var label = btn.get_node("Label")
		label.text = carta.nome
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sprite = btn.get_node_or_null("Sprite2D")
		if sprite:
			if "arte" in carta and carta.arte != null:
				sprite.texture = carta.arte
			elif "Arte" in carta and carta.Arte != null:
				sprite.texture = carta.Arte
		
		var pode_usar = pa_atual >= carta.custo_energia
		if not pode_usar:
			btn.modulate = Color(0.35, 0.35, 0.35, 0.6)
			btn.scale = button_scale * 0.85
		else:
			btn.modulate = Color.WHITE
		
		var pos = _calcular_posicao_semicirculo(i, step)
		btn.position = pos
		
		btn.input_event.connect(
			func(_v, event, _s):
				if event is InputEventMouseButton and event.pressed:
					emit_signal("carta_clicada", carta)
					fechar()
		)
		btn.mouse_entered.connect(func(): _animar_hover_botao(btn, true))
		btn.mouse_exited.connect(func(): _animar_hover_botao(btn, false))
		buttons.append(btn)
		print("total: ", total, " | max_mag: ",  posicoes_laterais , " | step: ", step, " | radius: ", radius)
func _calcular_posicao_semicirculo(indice: int, step: float) -> Vector2:
	var angulo_central = -PI / 2.0
	var raio_x = radius * raio_x_multiplier  # mais largo na horizontal
	var raio_y = radius * raio_y_multiplier   # menos alto na vertical
	
	if indice == 0:
		return Vector2(cos(angulo_central) * raio_x, sin(angulo_central) * raio_y)
	
	var sinal = -1.0 if indice % 2 == 1 else 1.0
	var magnitude = int((indice + 1) / 2)
	var angulo = angulo_central + sinal * magnitude * step
	
	return Vector2(cos(angulo) * raio_x, sin(angulo) * raio_y)
	
	return Vector2(cos(angulo), sin(angulo)) * radius

func _criar_grid_pa() -> void:
	var cols = 4
	var spacing = Vector2(20, 20)
	var grid_y = radius + 1
	
	for i in range(max_pa):
		var col = i % cols
		var row = int(i / cols)
		
		var icone = Sprite2D.new()
		icone.texture = pa_cheia_texture
		icone.scale = Vector2(0.1, 0.1)
		
		var x_offset = (col - (cols - 1) / 2.0) * spacing.x
		var y_offset = row * spacing.y
		icone.position = Vector2(x_offset, grid_y + y_offset)
		
		add_child(icone)
		_pa_icons.append(icone)
	
	_atualizar_pa()

func definir_pa(pa_atual: int, pa_maximo: int) -> void:
	_pa_atual = pa_atual
	max_pa = pa_maximo
	_atualizar_pa()

func _atualizar_pa() -> void:
	for i in range(_pa_icons.size()):
		if i < _pa_atual:
			_pa_icons[i].modulate = Color.WHITE
		else:
			_pa_icons[i].modulate = Color(0.3, 0.3, 0.3, 0.5)

func _open_animation():
	for i in range(buttons.size()):
		var btn = buttons[i]
		var alvo = btn.scale
		btn.scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_interval(i * 0.05)
		tween.tween_property(btn, "scale", alvo, open_duration)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

func _close_animation() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_interval(i * 0.05)
		tween.tween_property(btn, "scale", Vector2.ZERO, open_duration * 0.5)
	
	await get_tree().create_timer(open_duration + buttons.size() * 0.05).timeout
	hide()

func _destroy_buttons() -> void:
	for btn in buttons:
		btn.queue_free()
	buttons.clear()

func _animar_hover_botao(btn: Area2D, entrando: bool) -> void:
	if not is_open:
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	if entrando:
		tween.tween_property(btn, "scale", button_scale * 1.2, 0.2)
	else:
		tween.tween_property(btn, "scale", button_scale, 0.2)
