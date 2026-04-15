extends Node3D

@onready var smoke: GPUParticles3D = get_node("VFX_Smoke") as GPUParticles3D

var last_position: Vector3
var min_speed: float = 0.05
var fade: float = 0.0
var fade_speed: float = 4.0

func _ready() -> void:
	last_position = global_position

func _process(delta: float) -> void:
	var moved: Vector3 = global_position - last_position
	var speed: float = moved.length() / maxf(delta, 0.00001)

	if speed > min_speed:
		fade = lerpf(fade, 1.0, delta * fade_speed)
	else:
		fade = lerpf(fade, 0.0, delta * fade_speed)

	if smoke != null:
		smoke.emitting = fade > 0.05
		smoke.amount_ratio = fade

	last_position = global_position
