
extends Area2D

var pecas_na_zona = []
@onready var collision_shape = $CollisionShape2D
@export var trail_particles_scene : PackedScene
func _ready():
	
	var rect = $ColorRect
	var radius = $CollisionShape2D.shape.radius
	rect.size = Vector2(radius * 2, radius * 2)
	rect.position = Vector2(-radius, -radius) # Centraliza
	
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
	if trail_particles_scene == null:
		push_warning("trail_particles_scene não está atribuída no inspetor.")
		return

	var trail = trail_particles_scene.instantiate()
	get_parent().add_child(trail)
	trail.global_position = body.global_position
	trail.emitting = true

	if trail.has_signal("finished"):
		trail.connect("finished", Callable(trail, "queue_free"))

func _saiu_do_gelo(body):
	
	body.friction = 0.98 
