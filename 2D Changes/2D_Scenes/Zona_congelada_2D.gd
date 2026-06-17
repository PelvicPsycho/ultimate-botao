
extends Area2D

var pecas_na_zona = []
@onready var collision_shape = $CollisionShape2D

# Friction padrão do projeto (caso a struct não esteja disponível)
const FRICTION_PADRAO: float = 0.98
const FRICTION_GELO: float = 1.0



func _physics_process(_delta):

	var todos_objetos = get_tree().get_nodes_in_group("PhysicsObjects")
	var raio_zona = collision_shape.shape.radius * global_scale.x
	var current_frame_pecas = []

	for body in todos_objetos:
		var dist = global_position.distance_to(body.global_position)

		if dist <= (raio_zona + body.radius):
			current_frame_pecas.append(body)
			if not body in pecas_na_zona:
				_entrou_no_gelo(body)

	for body in pecas_na_zona:
		if is_instance_valid(body) and not body in current_frame_pecas:
			_saiu_do_gelo(body)

	pecas_na_zona = current_frame_pecas

func _entrou_no_gelo(body):
	# A peça real continua recebendo o buff de friction para qualquer outro
	# sistema que leia diretamente dela, mas a fonte da verdade é a struct
	# do motor de física, então precisamos espelhar pra lá também.
	body.friction = FRICTION_GELO
	_set_friction_na_struct(body, FRICTION_GELO)

func _saiu_do_gelo(body):
	body.friction = FRICTION_PADRAO
	_set_friction_na_struct(body, FRICTION_PADRAO)

# Localiza a struct correspondente ao body no motor de física e atualiza
# a friction dela. Se não achar, não faz nada (a peça real já foi mexida).
func _set_friction_na_struct(body: Node, valor: float) -> void:
	var motor := _get_motor_de_fisica()
	if motor == null:
		return
	if motor.PhysicsObjects_List == null:
		return
	var lista: Array = motor.current_pitch_state.all_physic_object_list if motor.current_pitch_state != null else []
	for i in motor.PhysicsObjects_List.size():
		if motor.PhysicsObjects_List[i] == body and i < lista.size():
			lista[i].friction = valor
			return

func _get_motor_de_fisica() -> CollisionResolution2D:
	var no: Node = get_parent()
	while no != null:
		if no is CollisionResolution2D:
			return no
		no = no.get_parent()
	return null

