extends Node2D

@onready var CPUParticles = $CPUParticles2D

func emitExplosion(isHome:bool):
	if isHome:
		CPUParticles.color = CupManager.myTeam.cor
	else:
		CPUParticles.color = CupManager.currentCompetitor.cor
	CPUParticles.emitting = true
