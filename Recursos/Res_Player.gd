extends Resource
class_name TeamPlayer
enum Rank{S,A,B,C,D,F}

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

	
	slotsUpgrates.clear() # Limpa para garantir
	slotsUpgrates.resize(quantosSlotes)
	slotsUpgrates.fill(null) # Preenche com null para podermos validar depois
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
	var slot_livre = slotsUpgrates.find(null)
	if slot_livre != -1:
		match card.tipo_efeito:
			CardResource.TipoEfeito.FORCA:
				força += card.magnitude
				PA-= card.custo_energia
				
			CardResource.TipoEfeito.PA:
				PA += card.magnitude
				PA-= card.custo_energia
				
			
		slotsUpgrates[slot_livre] = card
		print("Status atualizado! Força: ", força, " | PA: ", PA)
		recalcular_status()
		print("Slotes de cartas atualizados: ", slotsUpgrates)
	else:
		print("Falha: Todos os ", quantosSlotes, " slots estão ocupados!")
	
