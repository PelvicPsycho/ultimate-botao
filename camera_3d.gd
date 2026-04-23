extends Camera3D

var allPieces

@export var zoom_speed: float

@export var min_zoom: Vector3
@export var max_zoom: Vector3

var target_zoom: Vector3

func _ready():
	allPieces = get_tree().get_nodes_in_group("Players")
	
	for piece in allPieces:
		piece.connect("zoom_out_signal", StartZoomOut)
		piece.connect("zoom_in_signal", EndZoomOut)
		

func _process(delta: float) -> void:
	# Smoothly lerp towards target zoom
	position.x = lerp(position.x, target_zoom.x, zoom_speed * delta)
	position.y = lerp(position.y, target_zoom.y, zoom_speed * delta)
	position.z = lerp(position.z, target_zoom.z, zoom_speed * delta)
	
	# Clamp zoom to prevent going too far
	position.x = clamp(position.x, min_zoom.x, max_zoom.x)
	position.y = clamp(position.y, min_zoom.y, max_zoom.y)
	position.z = clamp(position.z, min_zoom.z, max_zoom.z)

func StartZoomOut(pos: Vector3):
	#print("Start __________________")
	#print("pos = ", pos)
	#print("num players = ", allPieces.size())
	target_zoom = max_zoom
	
func EndZoomOut(pos: Vector3):
	#print("End ____________________")
	#print("pos = ", pos)
	#print("num players = ", allPieces.size())
	target_zoom = min_zoom
