extends PhysicsObject2D
class_name PhysicsPlayer2D_Simulation

@export var debug: bool = true

#region Simulation Needed Variables
var index: int
enum TeamSide {HOME, AWAY}
@export var teamSide: TeamSide

var radius: float

@export var Object_Radius: Node2D

#endregion



# Runtime Variables
var current_direction: Vector2 = Vector2.ZERO
var current_force: float = 0.0
var lerp_current_force: float = 0.0

var dono: PhysicsPlayer2D

var team: Team
@export var playerInfo: TeamPlayer
var playerInfo_atual: TeamPlayer

var canPlay: bool
var disabled: bool = false
var congelado: bool = false


signal turnPlayed


func _ready() -> void:
	team = playerInfo.time
	
	radius = (global_position - Object_Radius.global_position).length()

func loadPlayerInfo(plInfo):
	playerInfo_atual = plInfo.duplicate(true)
	playerInfo_atual.status_mudou.connect(atualizar_fisica_por_status)

	atualizar_fisica_por_status()
	
	Update_Values_With_StatusAtual()


func atualizar_fisica_por_status():
	# MASS
	# - Aumentar a massa torna a peça mais difícil de ser empurrada por outros
	mass = playerInfo_atual.basic_mass
	
	# Habilidade ativa - aumento_de_tamano
	if playerInfo_atual.aumento_de_tamano:
		mass = playerInfo_atual.basic_mass * 2.0   # dobra a massa

	# Habilidade ativa - diminui_de_tamano
	if playerInfo_atual.diminui_de_tamano:
		mass = playerInfo_atual.basic_mass * 0.5

	
	# FRICTION (0.0 to 1.0)
	# - é o quanto a peça perde velocidade enquanto se desloca
	# - quanto maior for o valor, - fricção será aplicado
	# - quanto menor for o valor, + fricção será aplicado
	friction = playerInfo_atual.basic_friction
	
	# Habilidade ativa - more_friction
	if playerInfo_atual.more_friction:
		friction = playerInfo_atual.basic_friction - 0.05

	# Habilidade ativa - less_friction
	if playerInfo_atual.less_friction:
		friction = playerInfo_atual.basic_friction + 0.05
	
	if friction >= 1:
		friction = 0.99

	
func Update_Values_With_StatusAtual() -> void:
	mass = playerInfo_atual.basic_mass
	friction = playerInfo_atual.basic_friction

func definir_estado_visual(ativo: bool) -> void:
	self.canPlay = ativo

#region Movement
func Execute_Action() -> void:
	if is_frozen():
		return
	
	Set_Current_Velocity(current_direction * current_force)
	
	turnPlayed.emit()

func move_object(_delta: float) -> void:
	var new_velocity = current_velocity * friction;
	Set_Current_Velocity(new_velocity)
	
	if abs(current_velocity.x) < 10 && abs(current_velocity.y) < 10:
		Set_Current_Velocity(Vector2.ZERO)
		is_moving = false
	else:
		is_moving = true

#endregion

#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position

	if not (object_collided is PhysicsPlayer2D):
		return
	
	if get_instance_id() > object_collided.get_instance_id():
		return
	if playerInfo_atual and playerInfo_atual.congelamento_ativo:
		if object_collided.has_method("aplicar_congelamento"):
			object_collided.aplicar_congelamento(playerInfo_atual.poder_congelar_turnos)
			playerInfo_atual.congelamento_ativo = false
				
	if playerInfo_atual and playerInfo_atual.empurra_aliados_ativo:
		# Verifica se quem bateu é do MESMO TIME (aliado)
		if object_collided.team == self.team:
			if object_collided.has_method("aplicar_empurrao"):
				# Passa a velocidade atual para dar o boost
				
				object_collided.aplicar_empurrao(self.current_velocity)
				# Gasta o poder após usar
				playerInfo_atual.empurra_aliados_ativo = false	

#endregion



#region Merge
func is_frozen() -> bool:
	if playerInfo_atual:
		return playerInfo_atual.disabilitado or playerInfo_atual.turnos_congelamento_armazenado > 0
	return false


func aplicar_congelamento(turnos: int) -> void:
	print("Peça congelada por ", turnos, " turnos!")
	current_velocity = Vector2.ZERO
	Set_Current_Velocity(Vector2.ZERO)
	if playerInfo_atual:
		playerInfo_atual.turnos_congelamento_armazenado = turnos
		playerInfo_atual.disabilitado = true
		playerInfo_atual.status_mudou.emit()

#endregion
