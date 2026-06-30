extends CanvasLayer

@export var bottom_nav: HBoxContainer

@export_group("Telas (Submenus)")
## Arraste o nó Control raiz do seu Menu Elenco aqui
@export var tela_elenco: Control
## Arraste o nó Control raiz do seu Menu de Torneios aqui
@export var tela_torneios: Control
## Arraste o nó Control raiz do seu Menu de Configurações aqui
@export var tela_config: Control
@export var tela_selection: Control

var tela_atual: Control = null
var indice_atual: int = 0 # 0 é o índice inicial (botão Torneios)

# Configurações de "Gamefeel" dos Botões
const REBOUND_TIME = 0.15
const REBOUND_EASE = Tween.EASE_OUT
const REBOUND_TRANS = Tween.TRANS_BACK

# Configurações de Transição das Telas (Panning)
const PAN_TIME = 0.35
const PAN_EASE = Tween.EASE_OUT
const PAN_TRANS = Tween.TRANS_CUBIC

# Guardamos o tween atual para cancelá-lo se o jogador clicar rápido demais
var _tween_transicao: Tween

func _ready():
	for child in bottom_nav.get_children():
		if child is TextureButton:
			child.button_up.connect(_on_button_up.bind(child))
			
	# Garante que as telas extras comecem escondidas
	if tela_elenco: tela_elenco.hide()
	if tela_config: tela_config.hide()
	if tela_selection: tela_selection.hide()
			
	# Inicia já com a aba do meio (Torneios) aberta
	var botao_inicial = bottom_nav.get_child(indice_atual) 
	if botao_inicial is TextureButton:
		if tela_torneios:
			tela_torneios.show()
			tela_atual = tela_torneios
		call_deferred("_on_button_up", botao_inicial)


# --- ANIMAÇÃO DE SELEÇÃO E DESTAQUE (Up) ---
func _on_button_up(button: TextureButton):
	var tween = create_tween().set_parallel(true)
	
	for btn in bottom_nav.get_children():
		if btn is TextureButton:
			btn.pivot_offset = btn.size / 2.0
			
			var animador: AnimadorHover = null
			for filho in btn.get_children():
				if filho is AnimadorHover:
					animador = filho
					break
			# ----------------------------------
			
			if btn == button:
				# Botão Selecionado: Trava o hover e fica grande
				if animador: animador.esta_selecionado = true
				
				tween.tween_property(btn, "scale", Vector2(1.35, 1.35), REBOUND_TIME).set_trans(REBOUND_TRANS).set_ease(REBOUND_EASE)
				tween.tween_property(btn, "modulate", Color(1.2, 1.2, 1.2), REBOUND_TIME)
			else:
				# Botão Inativo: Destrava o hover e volta ao normal
				if animador: animador.esta_selecionado = false
				
				tween.tween_property(btn, "scale", Vector2(1.0, 1.0), REBOUND_TIME).set_ease(Tween.EASE_OUT)
				tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), REBOUND_TIME)

	# --- LÓGICA DE ABAS ---
	var tela_alvo: Control = null
	match button.name:
		"MyTeam_TextureButton":
			tela_alvo = tela_elenco
		"Torneio_TextureButton":
			tela_alvo = tela_torneios
		"Configurações_TextureButton":
			tela_alvo = tela_config
		"Selection_TextureButton":
			tela_alvo = tela_selection
			
	var indice_alvo = button.get_index()
	
	if tela_alvo and tela_alvo != tela_atual:
		_transicao_panning(tela_alvo, indice_alvo)


# Função que cria o efeito de empurrar a tela
func _transicao_panning(tela_alvo: Control, indice_alvo: int) -> void:
	if _tween_transicao and _tween_transicao.is_running():
		_tween_transicao.kill() # Evita bugs se o jogador clicar loucamente

	# 1. Sincroniza dados do Elenco caso estejamos saindo dele
	if tela_atual == tela_elenco:
		_sincronizar_elenco()
		
	var tela_saindo = tela_atual
	tela_atual = tela_alvo
	
	# Usamos a largura do viewport para saber o quanto empurrar a tela para fora.
	# Se os submenus não ocupam a tela toda, troque isso pela largura do painel.
	var distancia_slide = get_viewport().get_visible_rect().size.x
	
	# 2. Descobre a direção com base no índice dos botões
	var indo_para_direita = indice_alvo > indice_atual
	indice_atual = indice_alvo
	
	# Calcula as posições no Eixo X (Assumindo que o "centro" da tela alvo é X = 0)
	var pos_centro = 0.0
	var pos_escondida_esquerda = -distancia_slide
	var pos_escondida_direita = distancia_slide
	
	# 3. Prepara a nova tela na posição inicial correta (fora de cena)
	tela_alvo.show()
	if indo_para_direita:
		tela_alvo.position.x = pos_escondida_direita
	else:
		tela_alvo.position.x = pos_escondida_esquerda

	# 4. Inicia a animação (Tween)
	_tween_transicao = create_tween().set_parallel(true)
	
	# Traz a tela alvo para o centro
	_tween_transicao.tween_property(tela_alvo, "position:x", pos_centro, PAN_TIME)\
		.set_trans(PAN_TRANS).set_ease(PAN_EASE)
		
	# Empurra a tela antiga para fora
	if tela_saindo:
		var destino_saida = pos_escondida_esquerda if indo_para_direita else pos_escondida_direita
		_tween_transicao.tween_property(tela_saindo, "position:x", destino_saida, PAN_TIME)\
			.set_trans(PAN_TRANS).set_ease(PAN_EASE)
			
		# Quando a animação inteira terminar, escondemos o nó antigo (para não renderizar off-screen e economizar processamento)
		_tween_transicao.chain().tween_callback(tela_saindo.hide)

# --- A SUBSCRIÇÃO DA SUA FUNÇÃO DE SAVE/SYNC ---
func _sincronizar_elenco() -> void:
	SaveManager.save_game()
	
	# Pega a quantidade de slots direto da tela de elenco (ou usa 3 como segurança)
	var tamanho_slots = 3
	if tela_elenco and "slot_buttons" in tela_elenco:
		tamanho_slots = tela_elenco.slot_buttons.size()
		
	var num_titulares = mini(tamanho_slots, GameState.jogadores.size())
	
	CupManager.myTeam.mainSquad.clear()
	for i in range(num_titulares):
		CupManager.myTeam.mainSquad.append(GameState.jogadores[i])
		
	CupManager.myTeam.collectedSquad.clear()
	for i in range(num_titulares, GameState.jogadores.size()):
		CupManager.myTeam.collectedSquad.append(GameState.jogadores[i])
		
	print("✔ Alterações no elenco salvas e sincronizadas com o CupManager!")

func _on_versus_texture_button_pressed():
	pass # Replace with function body.
