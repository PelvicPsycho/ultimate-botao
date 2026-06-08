extends Node2D

@onready var CPUParticles = $CPUParticles2D

func emitExplosion(isHome:bool):
	if isHome:
		CPUParticles.color = CupManager.myTeam.cor if !PvPManager.isPvpMatch else PvPManager.teams[0].cor
	else:
		CPUParticles.color = CupManager.currentCompetitor.cor if !PvPManager.isPvpMatch else PvPManager.teams[1].cor
	CPUParticles.emitting = true
