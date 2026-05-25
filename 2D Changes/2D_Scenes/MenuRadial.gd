extends Node2D

signal carta_clicada(carta)

@export var radius: float = 100.0
@export var angular_start: float = 0.0  # em graus, 0 = direita
@export var open_duration: float = 0.2
@export var button_scale := Vector2(1,1)

var buttons: Array[Area2D] = []
var labels: Array[Label] = []
var is_open: bool = false

func _ready() -> void:
	hide()

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
	
func definir_cartas(cartas: Array) -> void:
	_destroy_buttons()
	if cartas.is_empty():
		return
	var count = cartas.size()
	var angle_step = 360.0 / count
	for i in range(count):
		var carta = cartas[i]
		var btn = $ButtonModel.duplicate()
		btn.visible = true
		btn.scale = button_scale
		add_child(btn)
		var label = btn.get_node("Label")
		label.text = carta.nome
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ang = deg_to_rad(angular_start + i * angle_step)
		btn.position = Vector2(cos(ang), sin(ang)) * radius
		var collider = btn.get_node("CollisionShape2D")
		collider.disabled = false
		btn.input_event.connect(
			func(_v, event, _s):
			if event is InputEventMouseButton and event.pressed:
				emit_signal("carta_clicada", carta)
				fechar()
		)
		buttons.append(btn)

func _on_button_input(_v, event, _s, index, carta):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("carta_clicada", carta)
		fechar()
func _open_animation():
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.scale = Vector2.ZERO

		var tween = create_tween()
		tween.tween_interval(i * 0.05)
		tween.tween_property(btn, "scale", Vector2.ONE, open_duration)\
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
	labels.clear()
