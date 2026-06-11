extends Node
class_name AnimadorHover

@export_group("Animação")
@export var escala_hover := Vector2(1.1, 1.1)
@export var tempo_animacao := 0.15

@export_group("Áudio")
## Arraste o arquivo de som de Hover (passar o mouse) aqui
@export var som_hover: AudioStream
## Arraste o arquivo de som de Clique aqui
@export var som_clique: AudioStream

# 1. Mudamos de BaseButton para Control, abrangendo TODOS os elementos de UI
var alvo_pai: Control
var escala_original: Vector2
var tween_atual: Tween

var esta_selecionado: bool = false:
	set(valor):
		esta_selecionado = valor
		if tween_atual:
			tween_atual.kill()

var esta_bloqueado: bool = false:
	set(valor):
		esta_bloqueado = valor
		if esta_bloqueado and tween_atual:
			tween_atual.kill()

func _ready() -> void:
	alvo_pai = get_parent() as Control
	if alvo_pai:
		escala_original = alvo_pai.scale
		alvo_pai.pivot_offset = alvo_pai.size / 2.0
		
		# 2. Labels e TextureRects geralmente vêm com o filtro de mouse 
		# em "Ignore", o que os deixa invisíveis para o mouse. 
		# Essa linha garante que eles passem a "sentir" o ponteiro.
		if alvo_pai.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			alvo_pai.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# 3. Conectamos os sinais universais da classe Control
		alvo_pai.mouse_entered.connect(_ao_entrar)
		alvo_pai.mouse_exited.connect(_ao_sair)
		alvo_pai.gui_input.connect(_processar_cliques)

# 4. Nova função que processa os cliques manualmente
func _processar_cliques(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_ao_clicar()
		else:
			_ao_soltar()

func _ao_entrar() -> void:
	if esta_selecionado or esta_bloqueado: return
	
	if som_hover != null:
		SoundMaster.play_button(som_hover)
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(alvo_pai, "scale", escala_original * escala_hover, tempo_animacao).set_trans(Tween.TRANS_SINE)

func _ao_sair() -> void:
	if esta_selecionado or esta_bloqueado: return
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(alvo_pai, "scale", escala_original, tempo_animacao).set_trans(Tween.TRANS_SINE)

func _ao_clicar() -> void:
	if esta_selecionado or esta_bloqueado: return
	
	if som_clique != null:
		SoundMaster.play_button(som_clique)
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(alvo_pai, "scale", escala_original * 0.95, 0.05).set_trans(Tween.TRANS_SINE)

func _ao_soltar() -> void:
	if esta_selecionado or esta_bloqueado: return
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(alvo_pai, "scale", escala_original * escala_hover, tempo_animacao).set_trans(Tween.TRANS_SINE)
