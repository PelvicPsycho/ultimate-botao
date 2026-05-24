extends Camera2D

var allPieces

@export var zoom_speed: float

@export var min_zoom: Vector2
@export var max_zoom: Vector2

func _ready():
	# Get all playable pieces
	allPieces = get_tree().get_nodes_in_group("Players")
	
	# Conect "StartZoomOut" and "EndZoomOut" to playable pieces signals
	for piece in allPieces:
		piece.connect("zoom_out_signal", StartZoomOut)
		piece.connect("zoom_in_signal", EndZoomOut)
		

#func _process(delta: float) -> void:
	# Smoothly lerp towards target zoom
	#position.x = lerp(position.x, target_zoom.x, zoom_speed * delta)
	#position.y = lerp(position.y, target_zoom.y, zoom_speed * delta)
	#
	## Clamp zoom to prevent going too far
	#position.x = clamp(position.x, min_zoom.x, max_zoom.x)
	#position.y = clamp(position.y, min_zoom.y, max_zoom.y)

func StartZoomOut(pos: Vector2):
	#print("Start Zoom Out")
	pass
	
func EndZoomOut(pos: Vector2):
	#print("End Zoom Out")
	pass
