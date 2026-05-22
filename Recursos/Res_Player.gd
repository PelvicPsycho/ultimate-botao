extends Resource
class_name TeamPlayer

enum Rank {S, A, B, C, D, F}

signal status_mudou 

@export_category("Infos pessoais")
@export var id_unico: StringName #EX: "ronaldinho_gaucho_gremio"
@export var nome: String = ""
@export var num_camisa: int
var time: Team
@export var foto: Texture2D

@export_category("Habilidades")
@export var quantosSlotes: int
@export var geral: int
var slotsUpgrates: Array[CardResource] = []
var turnos_congelamento_armazenado: int = 0
@export var forca: int 
@export var PA: int
@export var rank: Rank
@export var disabilitado: bool = false
@export var turnos_preso:int
var congelamento_ativo: bool = false
var duracao_dos_buffs: Dictionary = {}
var ultima_carta_usada: CardResource = null
var troca_posicao_ativa: bool = false
var aumento_de_tamano:bool = false
var diminui_de_tamano:bool =false
var empurra_aliados_ativo = true
var empurra_aliados_multiplicador = 1.8 
var atrai_bola_ativo = false
var atrai_bola_forca = 1.0

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
	self.aumento_de_tamano = false
	self.diminui_de_tamano = false
	self.atrai_bola_ativo =false
func aplicar_buff(card: CardResource) -> void:
	# 1. A carta já está equipada: só ativa o efeito.
	ultima_carta_usada = card
	match card.tipo_efeito:
		CardResource.TipoEfeito.FORCA:
			forca += card.magnitude

		CardResource.TipoEfeito.PA:
			PA += card.magnitude
		CardResource.TipoEfeito.Congelamento:
			congelamento_ativo = true
			
		CardResource.TipoEfeito.TrocaLugar:
			troca_posicao_ativa = true
			
		CardResource.TipoEfeito.Grande:
			aumento_de_tamano = true
		CardResource.TipoEfeito.Pequeno:
			diminui_de_tamano = true
		CardResource.TipoEfeito.Empurrão:
			empurra_aliados_ativo = true
			empurra_aliados_multiplicador = card.magnitude
		CardResource.TipoEfeito.Atrasao:
			atrai_bola_ativo = true
			atrai_bola_forca = card.magnitude
			
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
