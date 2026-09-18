extends CollisionResolution2D_Tutorial
class_name CollisionResolution2D_AiTrain

func _ready() -> void:
	# Pega o nó raiz desta arena específica (o MatchScene dentro do Viewport)
	var arena_root: Node = owner if owner != null else get_parent()
	
	PhysicsObjects_List.clear()
	
	# Busca recursivamente apenas os nós que estão dentro DESTA arena
	for child in arena_root.find_children("*", "Node", true, false):
		if child.is_in_group("PhysicsObjects") and child is PhysicsObject2D:
			PhysicsObjects_List.append(child)
			
	print("[Arena %s] Peças carregadas: %d" % [arena_root.name, PhysicsObjects_List.size()])
	
	current_pitch_state = PitchState.new()
	current_pitch_state_loaded = false
	all_physicObjects_loaded = false
	
	var count = 0
	for object in PhysicsObjects_List:
		if object.is_in_group("Players"):
			if object.has_signal("ActionExecuted"):
				object.connect("ActionExecuted", Replicate_Action)
		object.index = count
		count += 1
	
	Set_Pitch_Simulation_Lines()
	
func handle_walls_collision(object_1: PhysicObject_Struct) -> void:
	# Se a sua arena tiver um centro definido (ou calculando pela média das paredes):
	# O vetor da parede deve sempre apontar na direção do interior do campo
	var arena_root: Node = owner if owner != null else get_parent()
	var pitch_center: Vector2 = Vector2(960, 589) # Posição central padrão do campo
	
	var middle_node = arena_root.find_child("Pitch_Middle_Point", true, false)
	if middle_node:
		pitch_center = middle_node.global_position
		
	var to_center = (pitch_center - object_1.last_position).normalized()
	
	# Se a normal de colisão estiver apontando para FORA do campo, invertemos ela:
	if wall_collision_normal.dot(to_center) < 0.0:
		wall_collision_normal = -wall_collision_normal
	
	# Empurra a peça de volta para dentro
	object_1.last_position += wall_collision_normal * wall_collision_depth
	
	# Reflete o vetor de velocidade
	object_1.current_velocity = object_1.current_velocity.bounce(wall_collision_normal)
	
	current_pitch_state.all_physic_object_list[object_1.index] = object_1
