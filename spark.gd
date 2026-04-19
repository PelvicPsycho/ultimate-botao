extends Node3D

@onready var particles: GPUParticles3D = $VFX_Spark

func _ready() -> void:
	particles.restart()
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
