extends Node

var jogadores: Array = []

## Estoque de cartas e peças: { id_unico : quantidade }
## Peças com 0 cartas equipadas são empilháveis (stack).
## Peças modificadas (com cartas) vivem em jogadores (fora do stack).
var cartas_desbloqueadas: Dictionary = {}
var pecas_desbloqueadas: Dictionary = {}
var ultimo_torneio_jogado: String = ""
## Lista com os nomes (cupName) dos torneios que o jogador já desbloqueou.
## O torneio mais fácil (Rank F) vem desbloqueado por padrão.
var torneios_desbloqueados: Array[String] = []

var TimerType: int  = 0

var finished_tutorial: bool = false

func _ready():
	jogadores = SaveManager.load_game()

# ── Helpers para Peças ──

func adicionar_peca(id: StringName, qtd: int = 1) -> void:
	pecas_desbloqueadas[id] = pecas_desbloqueadas.get(id, 0) + qtd

func remover_peca(id: StringName, qtd: int = 1) -> bool:
	var atual: int = pecas_desbloqueadas.get(id, 0)
	if atual < qtd:
		return false
	if atual == qtd:
		pecas_desbloqueadas.erase(id)
	else:
		pecas_desbloqueadas[id] = atual - qtd
	return true

func tem_peca(id: StringName) -> bool:
	return pecas_desbloqueadas.get(id, 0) > 0

func quantas_pecas(id: StringName) -> int:
	return pecas_desbloqueadas.get(id, 0)

# ── Helpers para Cartas ──

func adicionar_carta(id: StringName, qtd: int = 1) -> void:
	cartas_desbloqueadas[id] = cartas_desbloqueadas.get(id, 0) + qtd

func remover_carta(id: StringName, qtd: int = 1) -> bool:
	var atual: int = cartas_desbloqueadas.get(id, 0)
	if atual < qtd:
		return false
	if atual == qtd:
		cartas_desbloqueadas.erase(id)
	else:
		cartas_desbloqueadas[id] = atual - qtd
	return true

func tem_carta(id: StringName) -> bool:
	return cartas_desbloqueadas.get(id, 0) > 0

func quantas_cartas(id: StringName) -> int:
	return cartas_desbloqueadas.get(id, 0)

func imprimir_status_do_time() -> void:
	print("\n==================================================")
	print("📊 DIAGNÓSTICO DO ELENCO ATUAL")
	print("==================================================")
	for i in range(jogadores.size()):
		var player = jogadores[i]
		var f_atual = player.level_force if "level_force" in player else 1
		var pa_atual = player.PA if "PA" in player else 1
		
		print("\n📍 Slot %d: %s" % [i + 1, player.nome])
		print("   ↳ Força: %d | PA: %d" % [f_atual, pa_atual])
		
		for s in range(player.slotsUpgrates.size()):
			var carta = player.slotsUpgrates[s]
			if carta != null:
				print("     [%d] 🃏 %s" % [s + 1, carta.nome])
			else:
				print("     [%d] 🔲 [Vazio]" % [s + 1])
	print("==================================================\n")

#Funcao para soltar as cartas de uma peca numa fusao ou aposta e as cartas nao bugarem
func preparar_peca_para_fusao(peca: TeamPlayer): 
	for i in range(peca.slotsUpgrates.size()):
		if peca.slotsUpgrates[i] != null:
			print("Carta devolvida ao inventário: ", peca.slotsUpgrates[i].nome)
			peca.slotsUpgrates[i] = null
