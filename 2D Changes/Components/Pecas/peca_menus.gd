extends TextureRect
class_name PecaMenuUI

@export_group("Visual do Menu")
## Controla a transparência do overlay (0.0 = Invisível, 1.0 = Totalmente visível)
@export_range(0.0, 1.0, 0.05) var intensidade_overlay: float = 1.0
var player_info_g : TeamPlayer


## Chame esta função na hora de instanciar a peça no menu, passando o recurso
func setup_peca(player_info: TeamPlayer) -> void:
	player_info_g = player_info
#	print (player_info)
	if player_info == null or player_info.time == null:
		push_warning("PecaMenuUI: player_info ou o Team estão ausentes.")
		return
		
	var time = player_info.time
	
	# 1. Garante que o material do shader exista e o duplica para esta instância
	if material == null:
		push_warning("PecaMenuUI: O ShaderMaterial não foi anexado no Inspetor!")
		return
		
	# Impede que a cor de uma peça altere as outras peças na tela
	material = material.duplicate()
	
	# 2. Configura a Cor Base diretamente no Shader
	material.set_shader_parameter("sprite_tint", time.cor)
	
	# 3. Configura a Textura de Overlay e aplica a intensidade exportada
	var tex_menu = null
	if time.has_method("get_overlay_texture_menu"):
		tex_menu = time.get_overlay_texture_menu()
		
	if tex_menu != null:
		material.set_shader_parameter("overlay_texture", tex_menu)
		# Passa o valor do seu slider no editor direto para o shader!
		material.set_shader_parameter("overlay_mix_amount", intensidade_overlay)
	else:
		# Se não houver overlay, zera a mistura para não renderizar lixo visual
		material.set_shader_parameter("overlay_mix_amount", 0.0)

	# ====================================================================
	# 4. DIFERENCIAÇÃO VISUAL: MENU vs JOGO
	# ====================================================================
	
	# Garante que a peça do menu não sofra deformação elástica de arrasto
	material.set_shader_parameter("stretch_amount", 0.0) 
	
	# Reduz o tamanho da sombra no menu para a UI ficar mais "limpa" 
	material.set_shader_parameter("dist", 2)
