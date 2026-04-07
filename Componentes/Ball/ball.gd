extends RigidBody3D
class_name Ball

var lastTouch: Player

# Se a bola parecer girar muito lento, diminua o valor. Se girar muito rápido, aumente.
##Só serve para a bola redonda
@export var raio_da_bola: float = 0.5
@export var is_ball_redonda: bool = false

func _ready() -> void:
	set_physics_process(is_ball_redonda)

func _on_body_entered(body):
	if body.is_in_group("Players") or body is Player:
		#print('Tocou em ' + str(body))
		lastTouch = body

func _physics_process(_delta: float) -> void:
	# 1. Pega a velocidade com que a bola está deslizando pelo chão
	var velocidade_atual = linear_velocity
	velocidade_atual.y = 0 # Ignora o eixo Y para evitar cálculos errados
	
	var speed = velocidade_atual.length()
	
	# Se a bola estiver quase parando, zera a rotação para evitar tremedeira
	if speed < 0.1:
		angular_velocity = Vector3.ZERO
		return
		
	# 2. Descobre para qual lado ela está indo
	var direcao_movimento = velocidade_atual.normalized()
	
	# 3. Descobre o eixo exato de rotação (perpendicular ao movimento)
	var eixo_de_giro = Vector3.UP.cross(direcao_movimento).normalized()
	
	# 4. Aplica a rotação forçada! 
	# Velocidade Angular (w) = Velocidade Linear (v) / Raio (r)
	angular_velocity = eixo_de_giro * (speed / raio_da_bola)
