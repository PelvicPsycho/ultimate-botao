extends CanvasLayer


@export var bottom_nav: HBoxContainer

# Configurações de "Gamefeel"
# O tamanho que o botão vai "encolher" ou "crescer" no aperto
const SCALE_CLICK_FACTOR = 0.85
# O tempo que a animação de aperto leva
const CLICK_TIME = 0.05
# O tempo que a animação de retorno leva (levemente mais devagar)
const REBOUND_TIME = 0.15
# Transição do tipo "mola" ou "quique" para o retorno
const REBOUND_EASE = Tween.EASE_OUT
const REBOUND_TRANS = Tween.TRANS_BACK

func _ready():
	# Conecta automaticamente todos os botões filhos
	for child in bottom_nav.get_children():
		if child is TextureButton:
			# Quando o botão é pressionado (começa o clique)
			child.button_down.connect(_on_button_down.bind(child))
			# Quando o botão é liberado (termina o clique e executa a ação)
			child.button_up.connect(_on_button_up.bind(child))
			
	# --- NOVO CÓDIGO AQUI ---
	# Pega o segundo filho (índice 1) do HBoxContainer
	var botao_inicial = bottom_nav.get_child(1) 
	
	if botao_inicial is TextureButton:
		# Usa call_deferred para esperar o Godot calcular o tamanho do botão no primeiro frame
		# Se chamar direto, o size vai ser (0,0) e o pivô vai ficar no lugar errado!
		call_deferred("_on_button_up", botao_inicial)

# --- ANIMAÇÃO DE APERTO (Down) ---
func _on_button_down(button: TextureButton):
	# A MÁGICA ACONTECE AQUI:
	# Define o pivô no meio do botão usando o tamanho real calculado pelo Container
	button.pivot_offset = button.size / 2.0 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(SCALE_CLICK_FACTOR, SCALE_CLICK_FACTOR), CLICK_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(0.8, 0.8, 0.8), CLICK_TIME)

# --- ANIMAÇÃO DE LIBERAÇÃO E DESTAQUE (Up) ---
func _on_button_up(button: TextureButton):
	# Garante o pivô centralizado na hora de voltar também
	button.pivot_offset = button.size / 2.0
	
	for other_button in bottom_nav.get_children():
		if other_button is TextureButton and other_button != button:
			# Garante que os outros também tenham o pivô correto ao encolher
			other_button.pivot_offset = other_button.size / 2.0
			_animate_to_normal(other_button)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.35, 1.35), REBOUND_TIME).set_trans(REBOUND_TRANS).set_ease(REBOUND_EASE)
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), REBOUND_TIME)


	# --- SEU CÓDIGO DE ABAS AQUI ---
	# Exemplo: print("Abrir aba do botão: ", button.name)
	# match button.name:
	# 	"TextureButton1": show_elenco()
	# 	"TextureButton2": show_desafios()

# Função auxiliar para retornar botões não selecionados ao padrão
func _animate_to_normal(button: TextureButton):
	var tween = create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), REBOUND_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0), REBOUND_TIME)
