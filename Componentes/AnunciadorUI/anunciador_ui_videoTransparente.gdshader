shader_type canvas_item;

// A cor exata que colocamos no FFmpeg
uniform vec4 chroma_key_color : source_color = vec4(0.0, 0.847, 0.0, 1.0); 


// O quão agressivo o shader vai ser ao buscar a cor verde
uniform float threshold : hint_range(0.0, 1.0) = 0.52; 

// Para suavizar a borda da sua UI e evitar serrilhados muito duros
uniform float smoothing : hint_range(0.0, 1.0) = 0.15;

// Cor do time para tingir o vídeo (greyscale → cor do time)
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Mede a distância entre o pixel atual e o nosso verde-limão
    float diff = distance(tex_color.rgb, chroma_key_color.rgb);
    
    // Cria um recorte suave baseado nos nossos parâmetros
    float alpha_mask = smoothstep(threshold, threshold + smoothing, diff);
    
    // Aplica a máscara final com tint da cor do time
    COLOR = vec4(tex_color.rgb * color_tint.rgb, tex_color.a * alpha_mask);
}