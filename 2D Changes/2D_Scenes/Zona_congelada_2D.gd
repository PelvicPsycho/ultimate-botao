
extends Area2D

var pecas_na_zona = []
@onready var collision_shape = $CollisionShape2D



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
	
	body.friction = 1
	
func _saiu_do_gelo(body):
	
	body.friction = 0.98 
	
