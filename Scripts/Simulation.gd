extends Node
class_name  Simulation

func simulatePlays() -> Array[ShotPlayed]:
	return []

func evalPlay(play: ShotPlayed) -> int:
	# ------------------------------------------
	# CRITÉRIOS (DO MAIOR AO MENOR PESO):
	# - FEZ GOL
	# - MANUTENÇÃO DA POSSE
	# - DISTÂNCIA DA BOLA AO GOL DO PLAYER
	# - DISTÂNCIA DA BOLA AO GOL DA IA
	# - NÚMERO DE ADVERSÁRIOS BATIDOS
	# - POSIÇÃO FINAL DA PEÇA JOGADA
	# - TOMOU GOL
	# ------------------------------------------
	return -1

func pickBestPlay(plays: Array[ShotPlayed]) -> ShotPlayed:
	var bestPlay: ShotPlayed = null
	var bestPlayScore: int = int(-INF)
	for play in plays:
		var playScore = evalPlay(play)
		# SE O SCORE DA PLAY FOR MAIOR QUE A DA BEST PLAY ENTÃO BEST PLAY = PLAY
		if playScore > bestPlayScore:
			bestPlay = play
			bestPlayScore = playScore
	return bestPlay
