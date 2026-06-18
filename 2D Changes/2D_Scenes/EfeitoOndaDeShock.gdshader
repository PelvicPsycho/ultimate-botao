shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float forca : hint_range(0.0, 1.0) = 0.1;
uniform float tamanho : hint_range(0.0, 1.0) = 0.0;
uniform float espessura : hint_range(0.0, 1.0) = 0.1;
uniform float suavizacao_borda : hint_range(0.0, 0.5) = 0.08;

void fragment() {
    float dist = distance(UV, vec2(0.5));
    
    // Máscara da onda
    float mascara = smoothstep(tamanho - espessura, tamanho, dist) - smoothstep(tamanho, tamanho + espessura, dist);
    mascara = clamp(abs(mascara), 0.0, 1.0);
    
    // Máscara de borda: fade invertido do centro para as bordas do ColorRect
    float mascara_borda = smoothstep(0.5, 0.5 - suavizacao_borda, dist);
    mascara *= mascara_borda;

    if (mascara < 0.001) {
        discard;
    }

    vec2 direcao = normalize(UV - vec2(0.5));
    vec2 distorcao = direcao * forca * mascara;
    COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - distorcao);
}