extends Node

var jogadores: Array = []

# Guardam apenas os IDs do que o jogador conquistou.
# Restaurados diretamente pelo SaveManager.load_game().
var cartas_desbloqueadas: Array[StringName] = []
var pecas_desbloqueadas: Array[StringName] = []

func _ready():
	jogadores = SaveManager.load_game()

func imprimir_status_do_time() -> void:
	print("\n==================================================")
	print("📊 DIAGNÓSTICO DO ELENCO ATUAL")
	print("==================================================")
	for i in range(jogadores.size()):
		var player = jogadores[i]
		var f_atual = player.força if "força" in player else 50
		var pa_atual = player.PA if "PA" in player else 3
		
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
