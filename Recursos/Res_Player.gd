extends Resource
class_name TeamPlayer
enum Rank{S,A,B,C,D}

@export_category("Infos pessoais")
@export var nome: String = ""
@export var num_camisa: int
@export var time: Team

@export_category("Habilidades")
@export var quantosSlotes:int
@export var geral: int
var slotsUpgrates:Array[CardResource]=[]
@export var força:int
@export var PA:int
@export var rank:Rank
@export var disabilitado:bool
func inicializar_slots():
	slotsUpgrates.resize(quantosSlotes)
	slotsUpgrates.fill(null)
func equipar_card(card: CardResource, index: int):
	if index >= 0 and index < quantosSlotes:
		slotsUpgrates[index] = card
		recalcular_status()
func recalcular_status():
	# Exemplo: Reseta o geral para um valor base (ou você pode ter um geral_base)
	# Aqui, vamos supor que as cartas somam ao valor atual
	var bonus_geral = 0
	for card in slotsUpgrates:
		if card != null:
		# Supondo que seu CardResource tenha uma variável 'magnitude'
			bonus_geral += card.magnitude 
	
func aplicar_buff(card: CardResource):
	# Use o nome da classe do Enum para acessar os valores numéricos corretamente
	match card.tipo_efeito:
		CardResource.TipoEfeito.FORCA:
			força += card.magnitude
		CardResource.TipoEfeito.PA:
			PA += card.magnitude
	
	print("Status atualizado! Força: ", força, " | PA: ", PA)
	recalcular_status()
