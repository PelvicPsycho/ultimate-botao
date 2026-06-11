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

# Configurações de "Gamefeel"
const REBOUND_TIME = 0.15
const REBOUND_EASE = Tween.EASE_OUT
const REBOUND_TRANS = Tween.TRANS_BACK

func _ready():
	# Conecta automaticamente apenas o _on_button_up, 
	# já que o AnimadorHover cuida do _on_button_down.
	for child in bottom_nav.get_children():
		if child is TextureButton:
			child.button_up.connect(_on_button_up.bind(child))
			
	# Inicia já com a aba do meio (Torneios) aberta
	var botao_inicial = bottom_nav.get_child(1) 
	if botao_inicial is TextureButton:
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

	# --- LÓGICA DE ABAS E SAVE ---
	match button.name:
		"MyTeam_TextureButton":
			_alternar_telas(tela_elenco)
		"Torneio_TextureButton":
			_alternar_telas(tela_torneios)
		"Configurações_TextureButton":
			_alternar_telas(tela_config)
		"Selection_TextureButton":
			_alternar_telas(tela_selection)

# Função central que esconde o que não importa e mostra o alvo
func _alternar_telas(tela_alvo: Control) -> void:
	# 1. Verifica se estamos SAINDO do Menu Elenco para ir para outra tela
	if tela_atual == tela_elenco and tela_alvo != tela_elenco:
		_sincronizar_elenco()
	
	# 2. Esconde tudo
	if tela_elenco: tela_elenco.hide()
	if tela_torneios: tela_torneios.hide()
	if tela_config: tela_config.hide()
	if tela_selection: tela_selection.hide()
	
	# 3. Mostra apenas a tela que o botão mandou e atualiza o rastreador
	if tela_alvo:
		tela_alvo.show()
		tela_atual = tela_alvo

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
