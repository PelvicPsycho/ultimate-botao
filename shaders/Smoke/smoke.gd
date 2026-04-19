extends Node3D

@onready var particles: GPUParticles3D = $VFX_Smoke

func _ready() -> void:
	if particles:
		particles.one_shot = false
		particles.emitting = true
