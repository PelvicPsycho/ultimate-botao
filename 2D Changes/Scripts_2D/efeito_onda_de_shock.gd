extends Node2D

@onready var color_rect = $BackBufferCopy/ColorRect
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Toca a animação
	$AnimationPlayer.play("ShockWave")
	# Conecta o sinal de término para deletar com segurança
	$AnimationPlayer.animation_finished.connect(_on_finish)
	var tween = create_tween()
	# Anima a propriedade do shader de 0.0 até 1.0 em 0.5 segundos
	tween.tween_property(color_rect.material, "shader_parameter/tamanho", 1.0, 0.5).from(0.0)
	tween.finished.connect(queue_free)
func _on_finish(_anim_name: String) -> void:
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
