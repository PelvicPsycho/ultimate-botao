extends Node3D

@onready var viewport = $SubViewport
@onready var pincel = $SubViewport/Pincel
@onready var camera = $Camera3D 

# Mude para o caminho correto do seu MeshInstance3D
@onready var objeto_malha = $Botaoteste2/Botao

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pintar()

func pintar():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	if result:
		# --- RAIO-X DAS POSIÇÕES ---
		#print("Ponto exato do clique (Mundo): ", result.position)
		#print("Ponto convertido para a Malha (Local): ", objeto_malha.to_local(result.position))
		# ---------------------------
		
		var uv = calcular_uv_por_posicao(objeto_malha, result.position)
		
		if uv != Vector2(-1, -1):
			#print("📍 Pintura Perfeita no UV: ", uv)
			pincel.position = uv * Vector2(viewport.size)
		#else:
			#print("❌ O clique colidiu, mas não achou a malha visual por perto.")

# --- A MÁGICA: Busca Espacial Global (Imune a Rotações do 3ds Max) ---
func calcular_uv_por_posicao(mesh_instance: MeshInstance3D, hit_position: Vector3) -> Vector2:
	var mesh = mesh_instance.mesh
	var mdt = MeshDataTool.new()
	var best_uv = Vector2(-1, -1)
	var min_dist = 999999.0
	
	# Varre todas as superfícies da malha visual
	for i in range(mesh.get_surface_count()):
		mdt.create_from_surface(mesh, i)
		
		# Testa todos os triângulos
		for f in range(mdt.get_face_count()):
			var v_idx1 = mdt.get_face_vertex(f, 0)
			var v_idx2 = mdt.get_face_vertex(f, 1)
			var v_idx3 = mdt.get_face_vertex(f, 2)
			
			# 💡 O SEGREDO: Pegamos o vértice cru e convertemos para a posição Global real na cena!
			var v1 = mesh_instance.to_global(mdt.get_vertex(v_idx1))
			var v2 = mesh_instance.to_global(mdt.get_vertex(v_idx2))
			var v3 = mesh_instance.to_global(mdt.get_vertex(v_idx3))
			
			var uv1 = mdt.get_vertex_uv(v_idx1)
			var uv2 = mdt.get_vertex_uv(v_idx2)
			var uv3 = mdt.get_vertex_uv(v_idx3)
			
			# Agora usamos o hit_position diretamente, sem to_local()
			var v0 = v2 - v1
			var v1_edge = v3 - v1
			var v2_p = hit_position - v1
			
			var cross_prod = v0.cross(v1_edge)
			if cross_prod.length_squared() < 0.000001:
				continue 
				
			var normal = cross_prod.normalized()
			var dist_to_plane = abs(normal.dot(v2_p))
			
			# Aumentei a tolerância porque o seu objeto tem 3 centímetros (0.03 no mundo)
			if dist_to_plane > 0.5:
				continue
				
			var d00 = v0.dot(v0)
			var d01 = v0.dot(v1_edge)
			var d11 = v1_edge.dot(v1_edge)
			var d20 = v2_p.dot(v0)
			var d21 = v2_p.dot(v1_edge)
			
			var denom = d00 * d11 - d01 * d01
			if denom == 0: continue
			
			var v = (d11 * d20 - d01 * d21) / denom
			var w = (d00 * d21 - d01 * d20) / denom
			var u = 1.0 - v - w
			
			# Epsilon (Margem de borda) relaxado para abraçar a colisão
			var epsilon = 0.2
			if u >= -epsilon and v >= -epsilon and w >= -epsilon and u <= 1.0+epsilon and v <= 1.0+epsilon and w <= 1.0+epsilon:
				
				if dist_to_plane < min_dist:
					min_dist = dist_to_plane
					
					u = clamp(u, 0.0, 1.0)
					v = clamp(v, 0.0, 1.0)
					w = clamp(w, 0.0, 1.0)
					
					best_uv = (uv1 * u) + (uv2 * v) + (uv3 * w)
					
		mdt.clear()
		
	return best_uv


# Sistema de cores
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			pincel.modulate = Color(1, 0, 0)
		elif event.keycode == KEY_2:
			pincel.modulate = Color(0, 1, 0)
		elif event.keycode == KEY_3:
			pincel.modulate = Color(0, 0, 1)
