extends Label

@export var tamanho_maximo: int = 24
@export var tamanho_minimo: int = 10

var _ajustando: bool = false # <-- Nossa trava anti-recursão infinita

var texto_auto_ajustavel: String = "":
	set(novo_texto):
		texto_auto_ajustavel = novo_texto
		text = novo_texto
		_ajustar_texto()

func _ready() -> void:
	resized.connect(_ajustar_texto)

func _ajustar_texto() -> void:
	# 1. Trava anti-loop: se já está calculando, ignora o chamado engatilhado pelo "resized"
	if _ajustando:
		return
		
	# 2. Segurança extra: impede o cálculo se o Godot ainda não desenhou a cena (size.x é 0)
	if size.x <= 0:
		return

	_ajustando = true # Tranca a porta para novos chamados
	
	var fonte = get_theme_font("font")
	var tamanho_atual = tamanho_maximo
	
	# 3. Fazemos toda a matemática do tamanho apenas na memória (sem interagir com a UI)
	while fonte.get_string_size(text, horizontal_alignment, -1, tamanho_atual).x > size.x and tamanho_atual > tamanho_minimo:
		tamanho_atual -= 1
		
	# 4. Modificamos o tema do Godot APENAS UMA VEZ no final de tudo
	add_theme_font_size_override("font_size", tamanho_atual)
	
	_ajustando = false # Destranca a porta
