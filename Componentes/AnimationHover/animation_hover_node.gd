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

var botao_pai: BaseButton
var escala_original: Vector2
var tween_atual: Tween

var esta_selecionado: bool = false:
	set(valor):
		esta_selecionado = valor
		if tween_atual:
			tween_atual.kill()

func _ready() -> void:
	botao_pai = get_parent() as BaseButton
	if botao_pai:
		escala_original = botao_pai.scale
		botao_pai.pivot_offset = botao_pai.size / 2.0
		
		botao_pai.mouse_entered.connect(_ao_entrar)
		botao_pai.mouse_exited.connect(_ao_sair)
		botao_pai.button_down.connect(_ao_clicar)
		botao_pai.button_up.connect(_ao_soltar)

func _ao_entrar() -> void:
	if esta_selecionado: return 
	
	# --- TOCA O ÁUDIO DE HOVER NO SEU SINGLETON ---
	if som_hover != null:
		SoundMaster.play_button(som_hover)
		
		# Se futuramente quiser randomizar o tom do hover, pode usar a sua outra função assim:
		# SoundMaster.play_sfx(som_hover, randf_range(0.9, 1.1), 0.0)
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(botao_pai, "scale", escala_original * escala_hover, tempo_animacao).set_trans(Tween.TRANS_SINE)

func _ao_sair() -> void:
	if esta_selecionado: return 
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(botao_pai, "scale", escala_original, tempo_animacao).set_trans(Tween.TRANS_SINE)

func _ao_clicar() -> void:
	if esta_selecionado: return 
	
	# --- TOCA O ÁUDIO DE CLIQUE NO SEU SINGLETON ---
	if som_clique != null:
		SoundMaster.play_button(som_clique)
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(botao_pai, "scale", escala_original * 0.95, 0.05).set_trans(Tween.TRANS_SINE)

func _ao_soltar() -> void:
	if esta_selecionado: return 
	
	if tween_atual: tween_atual.kill()
	tween_atual = create_tween()
	tween_atual.tween_property(botao_pai, "scale", escala_original * escala_hover, tempo_animacao).set_trans(Tween.TRANS_SINE)
