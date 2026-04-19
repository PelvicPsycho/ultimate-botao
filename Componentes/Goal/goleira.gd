extends Node3D
class_name Goal
var material: ShaderMaterial
var outline_material: ShaderMaterial
enum TeamSide {HOME, AWAY}
@onready var mesh = $Goleira/StaticBody3D/Goleira

@export var team: TeamSide

signal gol(isHome: bool) #True = gol Home, False = gol Away (a principio)

func changeColor(color: int):
	material = ShaderMaterial.new()
	
	outline_material = ShaderMaterial.new()
	mesh.material_override = material
	outline_material.shader = load("res://shaders/outline_Complex.gdshader") as Shader
	outline_material.set_shader_parameter("outline_size",0.002)
	if color == 1:
		trocar_shader("res://shaders/Goleira_Azul.gdshader")
		
		var specular := Color(0.0745, 0.0745, 0.0745, 0.5019)

		material.set_shader_parameter("specular_color", specular)
		var fresnel := Color(0.51,0.51,0.51,0.77)
		material.set_shader_parameter("fresnel_color", fresnel)
		material.set_shader_parameter("specular_strength", 0.1)
		material.set_shader_parameter("fresnel_strength",0.77)
	else:
		trocar_shader("res://shaders/Goleira_Vermelha.gdshader")
		material.set_shader_parameter("specular_color", Color.html("#13131380"))
		material.set_shader_parameter("fresnel_color", Color.html("#003d354d"))
		material.set_shader_parameter("specular_strength", 0.1)
		material.set_shader_parameter("fresnel_strength",0.585)
	
	material.next_pass = outline_material
#	print("material override aplicado: ", mesh.material_override)
#	print("shader final: ", material.shader)
func trocar_shader(path: String) -> void:
	var shader := load(path) as Shader
	material.shader = shader
func _on_area_3d_body_entered(body: Node3D) -> void:
	
	#print('body entrou no gol: ' + str(body))
	if body.is_in_group('Balls'):
		#print('gol de: ' + str(true if team == TeamSide.HOME else false))
		gol.emit(true if team == TeamSide.HOME else false)
