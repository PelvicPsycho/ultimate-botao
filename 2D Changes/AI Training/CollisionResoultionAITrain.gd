extends CollisionResolution2D
class_name CollisionResoultion2DAITrain

func _ready() -> void:
	if not PvPManager.isPvpMatch:
		AI_Active = true
	else:
		AI_Active = false
		
	var nodes = get_tree().get_nodes_in_group("PhysicsObjects")
	for object in nodes:
		# Each arena owns its physics objects; other arenas may not be initialized yet.
		if is_ancestor_of(object):
			PhysicsObjects_List.append(object)
		
	print("number of players = ", PhysicsObjects_List.size())
	
	current_pitch_state = PitchState.new()
	current_pitch_state_loaded = false
	all_physicObjects_loaded = false
	
	var count = 0
	for object in PhysicsObjects_List:
		if object.is_in_group("Players"):
			object.Set_AI_Active(AI_Active)
			object.connect("ActionExecuted", Replicate_Action)
			
		object.index = count
		count += 1
	
	Set_Pitch_Simulation_Lines()
	for i in PhysicsObjects_List.size():
		current_pitch_state.all_physic_object_list.append(PhysicObject_Struct.new())

func set_pitch_state_variables_from_PhysicsObjects() -> void:
	if current_pitch_state.all_physic_object_list != null:
		current_pitch_state.all_physic_object_list.clear()
	
	for i in PhysicsObjects_List.size():
		var new_PhysicObject_Struct = current_pitch_state.all_physic_object_list[i]
		var node = PhysicsObjects_List[i]
		new_PhysicObject_Struct.index = node.index
		new_PhysicObject_Struct.last_position = node.global_position
		new_PhysicObject_Struct.current_velocity = node.current_velocity
		new_PhysicObject_Struct.mass = node.mass
		new_PhysicObject_Struct.friction = node.friction
		new_PhysicObject_Struct.scale = node.scale
		new_PhysicObject_Struct.radius = node.radius
		
		#var new_PhysicObject_Struct = PhysicObject_Struct.new()
		#new_PhysicObject_Struct.index = PhysicsObjects_List[i].index
		#new_PhysicObject_Struct.last_position = PhysicsObjects_List[i].global_position
		#new_PhysicObject_Struct.current_velocity = PhysicsObjects_List[i].current_velocity
		#
		#new_PhysicObject_Struct.mass = PhysicsObjects_List[i].mass
		#new_PhysicObject_Struct.friction = PhysicsObjects_List[i].friction
		#new_PhysicObject_Struct.scale = PhysicsObjects_List[i].scale
		#new_PhysicObject_Struct.radius = PhysicsObjects_List[i].radius
		
		if PhysicsObjects_List[i].is_in_group("Players"):
			new_PhysicObject_Struct.teamSide = PhysicsObjects_List[i].teamSide
			new_PhysicObject_Struct.is_a_player = true
			new_PhysicObject_Struct.level_force = PhysicsObjects_List[i].playerInfo_atual.level_force
			new_PhysicObject_Struct.level_force_weak = PhysicsObjects_List[i].playerInfo_atual.level_force_weak
			new_PhysicObject_Struct.level_force_strong = PhysicsObjects_List[i].playerInfo_atual.level_force_strong
			new_PhysicObject_Struct.current_min_force = PhysicsObjects_List[i].playerInfo_atual.get_min_force()
			new_PhysicObject_Struct.current_max_force = PhysicsObjects_List[i].playerInfo_atual.get_max_force()
			
			new_PhysicObject_Struct.atrai_bola_ativo = PhysicsObjects_List[i].playerInfo_atual.atrai_bola_ativo
			new_PhysicObject_Struct.atrai_bola_forca = PhysicsObjects_List[i].playerInfo_atual.atrai_bola_forca
			
		elif PhysicsObjects_List[i].is_in_group("Balls"):
			new_PhysicObject_Struct.is_a_player = false

		
		#if PhysicsObjects_List[i].last_PhysicObject_collided != null:
			#new_PhysicObject_Struct.last_touch_index = PhysicsObjects_List[i].last_PhysicObject_collided.index
		#else:
			#new_PhysicObject_Struct.last_touch_index = -1
		
		current_pitch_state.all_physic_object_list.append(new_PhysicObject_Struct) 
	
	reset_last_touch_of_all_pieces()
	
	current_pitch_state.home_score = match_state.homeScore
	current_pitch_state.away_score = match_state.awayScore
	
	current_pitch_state.middle_x = Pitch_Middle_Point.global_position.x
	current_pitch_state.middle_y = Pitch_Middle_Point.global_position.y
	
	current_pitch_state.can_score_goal = match_state.rallyCounter
	current_pitch_state.ball_possesion_counter = match_state.turnCounter
	current_pitch_state.current_team_playing = match_state.get_current_turn_int()
	
	current_pitch_state_loaded = true
