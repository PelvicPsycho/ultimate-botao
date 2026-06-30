extends PhysicsObject2D
class_name PhysicsBall2D

var firstTouch: PhysicsPlayer2D
var lastTouch: PhysicsPlayer2D

@export var debug: bool = true

#region Simulation Needed Variables
var index: int
var radius: float
@export var Object_Radius: Node2D

#endregion

@export var basic_min_force: float = 100.0
@export var basic_max_force: float = 1000.0
@export var basic_mass: float = 5.0
@export var basic_friction: float = 0.98
@export var basic_scale: float = 1

#region Rolling (UV Scroll)
## Multiplicador de velocidade do scroll. 1.0 = física real da esfera rolando.
@export var roll_multiplier: float = 1.5
var _last_position: Vector2
var _uv_offset: Vector2 = Vector2.ZERO
var _shader_material: ShaderMaterial
#endregion

func _ready() -> void:
	print("Mass = ", mass)
	print("friction = ", friction)
	
	radius = (global_position - Object_Radius.global_position).length()
	_last_position = global_position
	
	# Cria e aplica o shader de rolagem automaticamente
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = load("res://2D Changes/Shader_2d/ball_roll.gdshader")
	$Sprite2D.material = _shader_material


#region collisions
var last_PhysicObject_collided: PhysicsObject2D
var last_PhysicObject_collision_position: Vector2

func Set_Last_PhysicObject_Collision(collision_position: Vector2, object_collided: PhysicsObject2D) -> void:
	last_PhysicObject_collided = object_collided
	last_PhysicObject_collision_position = collision_position
	if firstTouch == null:
		firstTouch = object_collided
	lastTouch = object_collided
	#print("lastTouch object name = ", lastTouch.name)
	#print("lastTouch team name = ", lastTouch.team.name)
#endregion

#region Rolling

func _process(_delta: float) -> void:
	if not is_moving:
		_last_position = global_position
		return
	
	var displacement: Vector2 = global_position - _last_position
	var distance: float = displacement.length()
	
	if distance > 0.0 and radius > 0.0:
		# direction = para onde a bola está indo
		var direction: Vector2 = displacement / distance
		# A superfície visível rola no sentido OPOSTO ao movimento
		# Distância percorrida / circunferência = fração de volta completa
		var scroll_amount: float = distance / (2.0 * PI * radius)
		_uv_offset -= direction * scroll_amount * roll_multiplier
		_shader_material.set_shader_parameter("uv_offset", _uv_offset)
	
	_last_position = global_position

#endregion
