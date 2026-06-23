extends Node2D

@onready var particulas: GPUParticles2D = $GPUParticles2D
@onready var rachadura: Sprite2D = $Sprite2D

func _ready():

	rachadura.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(rachadura, "modulate:a", 0.8, 0.08)
	tween.parallel().tween_property(rachadura, "scale", Vector2(1.2, 1.2), 0.1)
	particulas.restart()
	await get_tree().create_timer(0.4).timeout
	var tween_out = create_tween()
	tween_out.tween_property(rachadura, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(particulas.lifetime).timeout
	queue_free()
