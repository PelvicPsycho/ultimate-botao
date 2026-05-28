shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size : hint_range(0.0, 20.0) = 3.0;
uniform float dim_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float alpha = base.a;
	
	float outline_alpha = 0.0;
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_size;
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(ps.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(ps.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, ps.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(0.0, ps.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(ps.x, ps.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(ps.x, ps.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(ps.x, -ps.y)).a);
	
	vec4 cor_final = mix(outline_color, texture(TEXTURE, UV), alpha);
	cor_final.a = max(alpha, outline_alpha);
	
	// Aplica escurecimento no sprite + outline
	float dim = 1.0 - dim_amount;
	COLOR = vec4(cor_final.rgb * dim, cor_final.a);
}