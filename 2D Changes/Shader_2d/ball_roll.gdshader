shader_type canvas_item;

uniform vec2 uv_offset = vec2(0.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.7;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec2 highlight_offset = vec2(-0.28, -0.28);
uniform float highlight_size : hint_range(0.01, 0.5) = 0.15;

// Novo: Controla o quanto a textura "estufa" no meio.
uniform float curvatura : hint_range(0.1, 1.0) = 0.5;

void fragment() {
	vec2 centered_uv = UV - 0.5;
	float dist = length(centered_uv) * 2.0;

	// Máscara circular
	if (dist > 1.0) {
		discard;
	}

	// --- A MÁGICA DO FALSO 3D (Spherize) ---
	// Calcula a altura da esfera (z será 1 no centro e 0 na borda extrema)
	float z = sqrt(1.0 - dist * dist);
	
	// Divide a UV pela altura para "puxar" os pixels do meio para a frente
	// O "+ curvatura" evita que a borda infinita quebre o desenho
	vec2 esfera_uv = centered_uv / (z + curvatura);
	// ---------------------------------------

	// Aplica o movimento do script na UV que agora está esférica
	vec2 scrolled_uv = esfera_uv + uv_offset;
	
	vec4 tex_color = texture(TEXTURE, fract(scrolled_uv + 0.5));
	
	// Sombra circular na borda (Volume)
	float shadow_falloff = 0.55;
	float shadow = smoothstep(shadow_falloff, 1.0, dist) * shadow_strength;
	
	// Brilho especular (Luz)
	float highlight_dist = length(centered_uv - highlight_offset);
	float highlight = smoothstep(highlight_size, 0.0, highlight_dist) * highlight_strength;
	
	vec3 color = tex_color.rgb * (1.0 - shadow);
	color += highlight;
	
	COLOR = vec4(color, tex_color.a);
}