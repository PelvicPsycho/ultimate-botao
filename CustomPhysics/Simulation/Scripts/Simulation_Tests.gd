extends Node2D

@export var original_solver: CollisionResolution2D_Simulation
@export var simulation_solver: SimulationController


#func _process(delta: float) -> void:
	#if original_solver.PhysicsObjects_List.size() != 0 and simulation_solver.PhysicsObjects_List.size() != 0:
		#
		#for i in range(original_solver.PhysicsObjects_List.size()):
			#if original_solver.PhysicsObjects_List[i].current_velocity != simulation_solver.PhysicsObjects_List[i].current_velocity:
				#print("original_solver ", original_solver.PhysicsObjects_List[i].index, " velocity = ", original_solver.PhysicsObjects_List[i].current_velocity)
				#print("simulation_solver ", original_solver.PhysicsObjects_List[i].index, " velocity = ", original_solver.PhysicsObjects_List[i].current_velocity)
				#print("Esta diferente")
				#print("Esta diferente")
			#else:
				#print("Esta igual")
