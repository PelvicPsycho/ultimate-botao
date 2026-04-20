extends RigidBody3D
class_name Ball

var lastTouch: Player

# Se a bola parecer girar muito lento, diminua o valor. Se girar muito rápido, aumente.
##Só serve para a bola redonda
@export var raio_da_bola: float = 0.5
@export var is_ball_redonda: bool = false

func _ready() -> void:
	set_physics_process(is_ball_redonda)
	max_contacts_reported = 4

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var maior_impulso := 0.0
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider is Player:
			var impulso = state.get_contact_impulse(i).length()
			if impulso > maior_impulso:
				maior_impulso = impulso
				lastTouch = collider

func _physics_process(_delta: float) -> void:
	# 1. Pega a velocidade com que a bola está deslizando pelo chão
	if sleeping:
		return

	var velocidade_atual = linear_velocity
	velocidade_atual.y = 0 # Ignora o eixo Y para evitar cálculos errados
	
	var speed = velocidade_atual.length()
	
	# Se a bola estiver quase parando, zera a rotação para evitar tremedeira
	if speed < 0.1:
		#Só alteramos a angular_velocity se ela ainda não for zero.
		# Isso evita que o corpo seja "acordado" a cada frame.
		if angular_velocity.length() > 0.01:
			angular_velocity = Vector3.ZERO
			
			# Dica extra: Se quiser ter certeza absoluta que ela para retoquei a linear também:
			linear_velocity = Vector3.ZERO 
		return
	
	# 2. Descobre para qual lado ela está indo
	var direcao_movimento = velocidade_atual.normalized()
	
	# 3. Descobre o eixo exato de rotação (perpendicular ao movimento)
	var eixo_de_giro = Vector3.UP.cross(direcao_movimento).normalized()
	
	# 4. Aplica a rotação forçada! 
	# Velocidade Angular (w) = Velocidade Linear (v) / Raio (r)
	angular_velocity = eixo_de_giro * (speed / raio_da_bola)
