extends Resource
class_name TeamPlayer

enum Rank {S, A, B, C, D, F}

# 1. A PONTE DE COMUNICAÇÃO (Obrigatório estar aqui)
signal status_mudou 

@export_category("Infos pessoais")
@export var nome: String = ""
@export var num_camisa: int
@export var time: Team
@export var foto: Texture2D
@export_category("Habilidades")
@export var quantosSlotes: int
@export var geral: int
var slotsUpgrates: Array[CardResource] = []

# 2. SEM O CEDILHA (Obrigatório ser 'forca' para casar com o script do Player)
@export var forca: int 
@export var PA: int
@export var rank: Rank
@export var disabilitado: bool

var duracao_dos_buffs: Dictionary = {}
func _init():
	slotsUpgrates.resize(quantosSlotes)
func inicializar_slots() -> void:
	if slotsUpgrates.size() == 0:
		slotsUpgrates.resize(quantosSlotes)
func recalcular_status() -> void:
	var bonus_geral: int = 0
	for card in slotsUpgrates:
		if card != null:
			bonus_geral += card.magnitude 

func resetar_status(base_info: TeamPlayer) -> void:
	self.forca = base_info.forca
	self.PA = base_info.PA 

func aplicar_buff(card: CardResource) -> void:
	# 1. A carta já está equipada: só ativa o efeito.
	match card.tipo_efeito:
		CardResource.TipoEfeito.FORCA:
			forca += card.magnitude

		CardResource.TipoEfeito.PA:
			PA += card.magnitude

	PA -= card.custo_energia
	duracao_dos_buffs[card] = card.duracao
	recalcular_status()
	status_mudou.emit()

	print("--- CARTA ATIVADA! ---")
	print("Nova Força: ", forca, " | PA: ", PA)

func processar_passagem_de_turno(base_info: TeamPlayer) -> void:
	processar_expiracao_de_buffs(base_info)

func processar_expiracao_de_buffs(base_info: TeamPlayer) -> void:
	var cartas_para_remover: Array[CardResource] = []
	
	for card in duracao_dos_buffs:
		duracao_dos_buffs[card] -= 1
		if duracao_dos_buffs[card] <= 0:
			_limpar_slot_da_carta(card)
			cartas_para_remover.append(card)
			
	if cartas_para_remover.size() > 0:
		for card in cartas_para_remover:
			duracao_dos_buffs.erase(card)
			print("acabou os buffs")
		resetar_status(base_info)
		for card_ativo in duracao_dos_buffs:
			_reaplicar_silencioso(card_ativo)
			
		# Avisa a peça que o buff acabou (círculo volta ao normal)
		status_mudou.emit()

func _limpar_slot_da_carta(card: CardResource) -> void:
	var idx: int = slotsUpgrates.find(card)
	if idx != -1: slotsUpgrates[idx] = null

func _reaplicar_silencioso(card: CardResource) -> void:
	if card.tipo_efeito == CardResource.TipoEfeito.FORCA: 
		forca += card.magnitude
	elif card.tipo_efeito == CardResource.TipoEfeito.PA: 
		PA += card.magnitude
