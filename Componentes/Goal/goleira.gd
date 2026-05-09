extends Node3D
class_name Goal
var material: ShaderMaterial
var outline_material: ShaderMaterial
enum TeamSide {HOME, AWAY}
@onready var mesh = $Goleira/StaticBody3D/Goleira

@export var team: TeamSide
@export var expulsar_forca_base: float = 3.0

signal gol(isHome: bool) #True = gol Home, False = gol Away (a principio)

func changeColor(team_material: ShaderMaterial):
	# 1. Duplicamos o material para que esta goleira tenha sua própria instância
	# Isso evita que buffs aplicados em peças interfiram na goleira e vice-versa
	var material_unico = team_material.duplicate()
	
	# 2. Aplicamos o material único
	mesh.material_override = material_unico
	
	# 3. Se precisar de Outline, configuramos aqui (apenas uma vez)
func trocar_shader(path: String) -> void:
	var shader := load(path) as Shader
	material.shader = shader

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group('Balls'):
		#print('gol de: ' + str(true if team == TeamSide.HOME else false))
		gol.emit(true if team == TeamSide.HOME else false)
#	elif body.is_in_group('Players'):
		#var bodySpeed = body.linear_velocity.length()
		#var bodyForce = expulsar_forca_base / (1.0 + bodySpeed)
		#var direcao := (body.global_position - global_position).normalized()
		#body.apply_central_impulse(direcao * bodyForce)
