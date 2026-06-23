shader_type canvas_item;
render_mode unshaded;

uniform vec2 ground_global_position;
uniform vec2 ground_size;
uniform sampler2D mask_texture : hint_default_black;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float forca : hint_range(-1.0, 1.0) = -0.1; // Negativo puxa para dentro
uniform float tamanho : hint_range(0.0, 1.0) = 0.5;
uniform float espessura : hint_range(0.0, 1.0) = 0.08;
uniform float suavizacao_borda : hint_range(0.0, 0.5) = 0.08;

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    float dist = distance(UV, vec2(0.5));
    
    // 1. Máscara da onda (lógica de impacto/distorção)
    float mascara = smoothstep(tamanho - espessura, tamanho, dist) - smoothstep(tamanho, tamanho + espessura, dist);
    mascara = clamp(abs(mascara), 0.0, 1.0);
    
    // Máscara de borda local (evita bordas quadradas do ColorRect)
    float mascara_borda = smoothstep(0.5, 0.5 - suavizacao_borda, dist);
    mascara *= mascara_borda;
    
    // Se a onda não estiver passando aqui, descarta o pixel (remove o quadrado branco)
    if (mascara < 0.001) {
        discard;
    }

    // 2. Recorte pelo formato do campo (World Space), escala 0.5
    if (ground_size.x > 0.01 && ground_size.y > 0.01) {
        vec2 ground_uv = (world_pos - (ground_global_position - ground_size * 0.5)) / ground_size;

        if (ground_uv.x < 0.0 || ground_uv.x > 1.0 || ground_uv.y < 0.0 || ground_uv.y > 1.0) {
            discard;
        }

        vec4 field_mask = texture(mask_texture, ground_uv);
        if (field_mask.a < 0.1) {
            discard;
        }
        
        mascara *= field_mask.a;
    }

    // 3. Distorção e correção do CanvasGroup
    vec2 direcao = normalize(UV - vec2(0.5));
    vec2 distorcao = direcao * forca * mascara;
    
    // Amostra a tela aplicando a distorção da onda
    vec4 screen = textureLod(screen_texture, SCREEN_UV - distorcao, 0.0);
    
    // Correção de divisão de alpha do CanvasGroup (remove o quadrado branco)
    if (screen.a > 0.0001) {
        screen.rgb /= screen.a;
    }
    
    // Leve brilho azulado/elétrico na onda de sucção
    vec3 cor_onda = vec3(0.2, 0.5, 1.0);
    screen.rgb = mix(screen.rgb, cor_onda, mascara * 0.25);
    
    COLOR = screen;
    COLOR.a = 1.0;
}