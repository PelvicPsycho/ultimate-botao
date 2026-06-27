extends Resource
class_name TeamPlayer

enum Rank {S, A, B, C, D}

signal status_mudou 

#@export_group("Infos pessoais")
@export var id_unico: StringName #EX: "ronaldinho_gaucho_gremio"
@export var nome: String = ""
@export var num_camisa: int
var time: Team
@export var foto: Texture2D
@export var textura_peca: Texture2D = preload("res://2D Changes/Components/Pecas/Textura_peca_campo.png")
#@export_range(0, 4) var overlay_texture: int = 1 #É definido no time
@export var material_shader: ShaderMaterial = preload("res://2D Changes/Components/Pecas/MaterialShaderPeças.tres")

@export_group("Basic Attributes")
@export var basic_min_force: float = 100.0
@export var basic_max_force: float = 1000.0
@export var basic_mass: float = 5.0
@export var basic_friction: float = 0.98
@export var basic_scale: float = 0.75

@export_group("Habilidades")
@export_subgroup("Slots")
var _quantosSlotes: int = 0
@export var quantosSlotes: int:
	set(value):
		_quantosSlotes = max(value, 0)
		slotsUpgrates.resize(_quantosSlotes)
		estimateRank()
	get:
		return _quantosSlotes
@export var slotsUpgrates: Array[CardResource] = []
@export var mao_cartas: Array[CardResource] = []
var turnos_congelamento_armazenado: int = 0
var poder_congelar_turnos: int = 0

@export_subgroup("Força")
@export var current_min_force: float = 100.0
@export var current_max_force: float = 1000.0
@export var level_force: int # nivel de força da peça (0 a 10)
@export var level_force_weak: int = 3  # Abaixo deste valor = FRACO
@export var level_force_strong: int = 7  # Acima deste valor = FORTE
var bonus_passivos: Dictionary = {}

@export_subgroup("PA e outros")
var _PA: int = 0
@export var PA: int: #Action Points em ptbr
	set(value):
		_PA = value
		estimateRank()
	get:
		return _PA
@export var disabilitado: bool = false
@export var turnos_preso:int
var rank: Rank = Rank.D

var congelamento_ativo: bool = false
var duracao_dos_buffs: Dictionary = {}
var ultima_carta_usada: CardResource = null
var troca_posicao_ativa: bool = false
var aumento_de_tamano:bool = false
var diminui_de_tamano:bool = false
var more_friction:bool = false
var less_friction:bool = false
var empurra_aliados_ativo = false
var empurra_aliados_multiplicador = 1.8 
var atrai_bola_ativo = false
var atrai_bola_forca = 1.0
var onda_choque_ativa = false
var peça_bomba_ativa  = false
var zona_Gelo_ativa = false
var escalaZonaGelo:float
@export_group("Tamanhos do Círculo Limite")
var escala_maxima_circulo_atual: float = 0.3
@export var escala_maxima_circulo_fraco: float = 0.3
@export var escala_maxima_circulo_normal: float = 0.4
@export var escala_maxima_circulo_forte: float = 0.6



func _init():
	slotsUpgrates.resize(quantosSlotes)

func estimateRank() -> Rank:
	var rankPoints = quantosSlotes + PA
	if rankPoints <= 4:
		rank = Rank.D
	elif rankPoints <= 8:
		rank = Rank.C
	elif rankPoints <= 12:
		rank = Rank.B
	elif rankPoints <= 16:
		rank = Rank.A
	elif rankPoints <= 20:
		rank = Rank.S
	return rank
	#else:
		#rank = Rank.F

func inicializar_slots() -> void:
	if slotsUpgrates.size() == 0:
		slotsUpgrates.resize(quantosSlotes)
		
func recalcular_status() -> void:
	var bonus_geral: int = 0
	for card in slotsUpgrates:
		if card != null:
			bonus_geral += card.magnitude 

func resetar_status(base_info: TeamPlayer) -> void:
	self.level_force = base_info.level_force
	
	self.aumento_de_tamano = false
	self.diminui_de_tamano = false
	self.atrai_bola_ativo = false
	self.troca_posicao_ativa = false
	self.congelamento_ativo = false
	self.turnos_preso = 0
	self.atrai_bola_ativo = false
	self.peça_bomba_ativa = false
	self.zona_Gelo_ativa = false 

func aplicar_buff(card: CardResource) -> void:
	
	if PA < card.custo_energia:
		print("PA insuficiente! Custa ", card.magnitude, " PA, tem apenas ", PA)
		return
	else:
		ultima_carta_usada = card
		match card.tipo_efeito:
			CardResource.TipoEfeito.FORCA:
				level_force += card.magnitude
			CardResource.TipoEfeito.PA:
				PA += card.magnitude
			CardResource.TipoEfeito.Congelamento:
				congelamento_ativo = true
				poder_congelar_turnos = card.magnitude
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
			CardResource.TipoEfeito.CartaOndaDeShock:
				onda_choque_ativa = true
			CardResource.TipoEfeito.PesaBomba:
				peça_bomba_ativa  = true
			CardResource.TipoEfeito.AreaDeGelo:
				zona_Gelo_ativa = true
				escalaZonaGelo = card.magnitude
		PA -= card.custo_energia
		if card.cartaRapida:
			duracao_dos_buffs[card] = max(1, card.duracaoLance)
		else:
		
			duracao_dos_buffs[card] = card.duracao
		recalcular_status()
		status_mudou.emit()
		print("--- CARTA ATIVADA! ---")
		print("Nova Força: ", level_force, " | PA: ", PA)

func aplicar_passivas() -> void:
	
	_remover_passivas()
	
	for card in slotsUpgrates:
		if card == null:
			continue
		if not card.is_passiva:
			continue
		
		match card.tipo_efeito:
			CardResource.TipoEfeito.Aumentar_Pa_Maximo:
				PA += card.magnitude
				bonus_passivos[card] = {"tipo": "PA", "valor": card.magnitude}
				
		print("Passiva ativada: ", card.nome, " | ", card.tipo_efeito)

func _remover_passivas() -> void:
	for card in bonus_passivos:
		var info = bonus_passivos[card]
		match info["tipo"]:
			"PA":
				PA -= info["valor"]
			"FORCA":
				level_force -= info["valor"]
	bonus_passivos.clear()

func processar_passagem_de_turno(base_info: TeamPlayer) -> void:
	processar_expiracao_de_buffs(base_info)
	
func processar_expiracao_de_lance(base_info: TeamPlayer) -> void:
	var cartas_para_remover: Array[CardResource] = []
	var houve_mudanca: bool = false
	
	
	var keys = duracao_dos_buffs.keys()
	
	for card in keys:
		if card.cartaRapida: 
			duracao_dos_buffs[card] -= 1 
			
			if duracao_dos_buffs[card] <= 0:
				_limpar_slot_da_carta(card)
				duracao_dos_buffs.erase(card)
				cartas_para_remover.append(card)
				houve_mudanca = true
				print("DEBUG: Carta rápida expirou: ", card.nome)

	if houve_mudanca:
		resetar_status(base_info)
		for card_ativo in duracao_dos_buffs:
			_reaplicar_silencioso(card_ativo)
		status_mudou.emit()
func processar_expiracao_de_buffs(base_info: TeamPlayer) -> void:
	if turnos_congelamento_armazenado > 0:
		turnos_congelamento_armazenado -= 1
		if turnos_congelamento_armazenado <= 0:
			disabilitado = false
			status_mudou.emit()
			
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
		status_mudou.emit()

func _limpar_slot_da_carta(card: CardResource) -> void:
	var idx: int = slotsUpgrates.find(card)
	if idx != -1: slotsUpgrates[idx] = null

func _reaplicar_silencioso(card: CardResource) -> void:
	if card.tipo_efeito == CardResource.TipoEfeito.FORCA: 
		level_force += card.magnitude
	elif card.tipo_efeito == CardResource.TipoEfeito.PA: 
		PA += card.magnitude

func get_min_force() -> float:
	current_min_force = basic_min_force + (100.0 * level_force)
	return current_min_force

func get_max_force() -> float:
	current_max_force = basic_max_force + (100.0 * level_force)
	return current_max_force
