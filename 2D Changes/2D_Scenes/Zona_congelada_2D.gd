extends Area2D

var pecas_na_zona = []
@onready var collision_shape = $CollisionShape2D
@onready var canvas_group = $CanvasGroup
@export var trail_particles_scene : PackedScene

func _ready():
	# gambiarra para pegar o chão e usar sua sprite com sua escala
	var chao = get_tree().get_first_node_in_group("Chao") as Sprite2D
	
	if chao and canvas_group:
		var mat = canvas_group.material as ShaderMaterial
		if mat:
			
			var real_size = chao.texture.get_size() * chao.global_scale
			
			
			mat.set_shader_parameter("mask_texture", chao.texture)
			mat.set_shader_parameter("ground_global_position", chao.global_position)
			mat.set_shader_parameter("ground_size", real_size)
	
	# Centralização do ColorRect
	var rect = $CanvasGroup/ColorRect
	var radius = collision_shape.shape.radius
	if rect:
		rect.size = Vector2(radius * 2, radius * 2)
		rect.position = Vector2(-radius, -radius)

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
	if trail_particles_scene:
		var trail = trail_particles_scene.instantiate()
		get_parent().add_child(trail)
		trail.global_position = body.global_position
		trail.emitting = true
		if trail.has_signal("finished"):
			trail.connect("finished", Callable(trail, "queue_free"))

func _saiu_do_gelo(body):
	body.friction = 0.98


func _on_tree_exiting() -> void:
	for body in pecas_na_zona:
		if is_instance_valid(body):
			_saiu_do_gelo(body)
	
	
	pecas_na_zona.clear()
	pass
