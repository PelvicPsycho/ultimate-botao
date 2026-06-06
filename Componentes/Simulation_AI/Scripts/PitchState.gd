extends Node
class_name PitchState

var all_physic_object_list: Array[PhysicObject_Struct]

var home_score: int
var away_score: int

var can_score_goal: int = 1
var ball_possesion_counter: int = 0

var current_team_playing: int
