extends GPUParticles2D


func _ready() -> void:
	# Cria um novo ParticleProcessMaterial
	var material := ParticleProcessMaterial.new()

	# Gravidade negativa leve para subida lenta
	material.gravity = Vector3(0.0, -5.0, 0.0)

	# Velocidade inicial e espalhamento
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 8.0
	material.spread = 180.0

	# Curva de escala: cresce e some
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.0))
	scale_curve.add_point(Vector2(0.5, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))

	var scale_curve_texture := CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	material.scale_curve = scale_curve_texture

	# Ramp de cor: alpha de 0.0 -> 0.5 -> 0.0
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.5, Color(1.0, 1.0, 1.0, 0.5))
	gradient.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))

	var color_ramp_texture := GradientTexture1D.new()
	color_ramp_texture.gradient = gradient
	material.color_ramp = color_ramp_texture

	# Turbulência orgânica habilitada
	material.turbulence_enabled = true

	# Aplica o material ao nó
	process_material = material

	print("DEBUG: Sistema de névoa rasteira (Opção 2) configurado e aplicado via script.")
