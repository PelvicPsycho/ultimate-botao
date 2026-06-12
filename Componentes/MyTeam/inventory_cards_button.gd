extends Button

@export_group("Referências de Nós")
@export var nome_label : Label
@export var imagem_icone : TextureRect
@export var quantidade_label: Label
@export var textura_raridade: TextureRect 
@export var borda_panel: Panel

@export_group("Cores por Raridade")
@export var cor_normal: Color = Color("9e9e9e") # Cinza
@export var cor_incomum: Color = Color("4caf50") # Verde
@export var cor_rara: Color = Color("ffc107") # Dourado (Amarelo)

var item_data: Resource

func _ready() -> void:
	# Garante que a borda comece invisível e o botão permita seleção
	if borda_panel:
		borda_panel.visible = false
		borda_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # Evita que o painel bloqueie cliques
		
	toggle_mode = true # Ativa o modo interruptor do botão
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	if borda_panel:
		borda_panel.visible = toggled_on

## quantidade: se > 1, mostra o label com o número. 0 ou omitido = invisível.
func setup_item(dados: Resource, quantidade: int = 0):
	item_data = dados
	
	if dados is CardResource:
		if nome_label:
			nome_label.text = dados.nome
			
		# --- APLICA A COR DA RARIDADE ---
		if textura_raridade:
			match dados.raridade:
				CardResource.Raridade.NORMAL:
					textura_raridade.modulate = cor_normal
				CardResource.Raridade.INCOMUN:
					textura_raridade.modulate = cor_incomum
				CardResource.Raridade.RARA:
					textura_raridade.modulate = cor_rara

	if quantidade_label:
		quantidade_label.visible = quantidade > 1
		if quantidade > 1:
			quantidade_label.text = str(quantidade)
