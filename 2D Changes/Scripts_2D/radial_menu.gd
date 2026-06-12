extends Node2D

signal carta_clicada(carta)

var is_open: bool = false
var _pa_atual: int = 0
var _animating := false
var _cartas: Array = []
var _outline_shader := preload("res://2D Changes/Shader_2d/outline2d.gdshader")

@onready var custo_container = $PopupInfo/CustoContainer
@onready var pa_slots_container = $PADots
@onready var popup_info = $PopupInfo
@onready var label_titulo =$PopupInfo/VBoxContainer/Titulo
@onready var label_desc =$PopupInfo/Descricao
@onready var popup_icone = $PopupInfo/VBoxContainer/ContentContainer/IconAnchor/IconeCarta
@export var icone_fogo_tex: Texture2D 
@onready var buttons: Array[Area2D] = [
	$BtnCentro, $BtnCima, $BtnDireita, $BtnBaixo, $BtnEsquerda
]

func _ready() -> void:
	popup_info.hide()
	for btn in buttons:
		btn.input_pickable = true
		btn.input_event.connect(_on_btn_click.bind(btn))
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		btn.visible = false
		btn.scale = Vector2.ZERO
	hide()

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

func definir_cartas(cartas: Array, pa_atual: int = 0, max_pa: int = 8) -> void:
	_cartas = cartas
	definir_pa(pa_atual, max_pa)
	
	for btn in buttons:
		btn.visible = false
		btn.remove_meta("carta")
	
	for i in range(min(cartas.size(), buttons.size())):
		var btn = buttons[i]
		var carta = cartas[i] 
		btn.visible = true
		btn.set_meta("carta", carta)
		
		
		var icone = btn.get_node_or_null("Art")
		if icone:
			icone.texture = carta.arte
			icone.visible = (carta.arte != null)
			icone.modulate.a = 1.0
		
		var custo = carta.custo_energia
		btn.modulate = Color(1, 1, 1, 0.6) if _pa_atual >= custo else Color(0.3, 0.3, 0.3, 0.2)
	
	abrir()

func _on_btn_hover(btn: Area2D) -> void:
	if _animating or not btn.visible: return
	var carta = btn.get_meta("carta") as CardResource
	
	
	label_titulo.text = carta.nome
	
	
	if popup_icone:
		popup_icone.texture = carta.arte
		if carta.arte:
			var tex_size = carta.arte.get_size()
			var alvo = 100
			var scale_factor = alvo / max(tex_size.x, tex_size.y)
			popup_icone.scale = Vector2(scale_factor, scale_factor)
			
			popup_icone.position = Vector2(32, 32)
	
	label_desc.text = carta.descricao
	
	
	for child in custo_container.get_children():
		child.queue_free()
	
	for i in range(carta.custo_energia):
		var rect = TextureRect.new()
		rect.texture = icone_fogo_tex
		rect.custom_minimum_size = Vector2(24, 24)
		rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		custo_container.add_child(rect)
	

	popup_info.global_position = global_position + Vector2(-popup_info.size.x / 2, -250)
	popup_info.show()
	popup_info.modulate.a = 0.0
	create_tween().tween_property(popup_info, "modulate:a", 1.0, 0.15)
	
	print("DEBUG: Layout final do popup: Título no topo, Ícone e Descrição lado a lado.")
func _on_btn_unhover(btn: Area2D) -> void:
	if _animating or not btn.visible: return
	popup_info.hide()
	
	var fundo = btn.get_node_or_null("Sprite2D")
	if fundo: fundo.material = null
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)
	
	if btn.has_meta("carta"):
		var custo = btn.get_meta("carta").custo_energia
		var alpha_alvo = 0.6 if _pa_atual >= custo else 0.3
		tween.tween_property(btn, "modulate:a", alpha_alvo, 0.12)

func abrir() -> void:
	if is_open or _animating: return
	is_open = true
	show()
	for i in range(buttons.size()):
		if buttons[i].visible:
			create_tween().tween_property(buttons[i], "scale", Vector2.ONE, 0.3).set_delay(i * 0.05)

func fechar() -> void:
	is_open = false
	popup_info.hide()
	for btn in buttons:
		if btn.visible:
			create_tween().tween_property(btn, "scale", Vector2.ZERO, 0.2)
	await get_tree().create_timer(0.2).timeout
	hide()

func _on_btn_click(_viewport, event, _shape_idx, btn):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if btn.has_meta("carta"):
			emit_signal("carta_clicada", btn.get_meta("carta"))
			fechar()
