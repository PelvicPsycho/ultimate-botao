extends Node
class_name PitchState

var all_physic_object_list: Array[PhysicObject_Struct]

var last_ball: PhysicObject_Struct

var home_score: int
var away_score: int

var can_score_goal: int = 1
var ball_possesion_counter: int = 0

var current_team_playing: int

var play_that_resulted_on_this_pitch_state: Play

var score: int
