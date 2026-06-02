shader_type canvas_item;

uniform sampler2D textura_infinita : repeat_enable;
uniform float velocidade_scroll = 0.05;

void fragment() {
	vec2 uv_deslocada = UV;
	uv_deslocada.x += TIME * velocidade_scroll;
	
	vec4 cor_final = texture(textura_infinita, uv_deslocada);
	
	// SE O PIXEL FOR QUASE TRANSPARENTE, DESTRÓI ELE!
	// (0.05 significa que qualquer coisa com menos de 5% de opacidade some)
	if (cor_final.a < 0.55) {
		discard; 
	}
	
	COLOR = cor_final;
}