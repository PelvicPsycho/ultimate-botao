extends Button

@export var nome_label: Label
@export var peca_visual: PecaMenuUI
@export var rank_label: Label
@export var quantidade_label: Label
@export var borda_panel: Panel

@export_group("Destaque Visual")
@export var textura_destaque: TextureRect # Arraste o TextureRect que vai mudar de cor aqui
@export var cor_selecionada: Color = Color(1.0, 1.0, 0) # Ex: Amarelo suave. Escolha no Inspector!

func _ready() -> void:
	# Garante que a borda comece invisível e o botão permita seleção
	if borda_panel:
		borda_panel.visible = false
		borda_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # Evita que o painel bloqueie cliques
		rank_label._ajustar_texto()
		
	toggle_mode = true # Ativa o modo interruptor do botão
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	# 1. Liga/Desliga a borda que você já tinha configurado
	if borda_panel:
		borda_panel.visible = toggled_on
		
	# 2. Muda a cor do TextureRect suavemente
	if textura_destaque:
		var tween = create_tween()
		
		# Define o alvo: se ligou, vai pra cor_selecionada. Se desligou, volta pro branco puro.
		var cor_alvo = cor_selecionada if toggled_on else Color.WHITE
		
		# Faz a transição de cor durar 0.15 segundos para dar um efeito "macio"
		tween.tween_property(textura_destaque, "modulate", cor_alvo, 0.15)

## quantidade: se > 1, mostra o label com o número. 0 ou omitido = invisível.
func setup_item(dados: Resource, quantidade: int = 0):
	if dados is TeamPlayer:
		if nome_label:
#			nome_label.text = dados.nome
			nome_label.texto_auto_ajustavel = dados.nome
			
		if rank_label:
			dados.estimateRank()
			var dadosRank = dados.rank
			var rank_keys := TeamPlayer.Rank.keys()
			if typeof(dadosRank) == TYPE_INT and dadosRank >= 0 and dadosRank < rank_keys.size():
				rank_label.text = rank_keys[dadosRank]
			else:
				rank_label.text = str(dadosRank)
		
		if is_instance_valid(peca_visual):
#			peca_visual.show()
			peca_visual.setup_peca(dados)
	
	if quantidade_label:
		quantidade_label.visible = quantidade > 1
		if quantidade > 1:
			quantidade_label.text = str(quantidade)
