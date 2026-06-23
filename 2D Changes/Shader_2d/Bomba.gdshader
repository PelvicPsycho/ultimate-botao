shader_type canvas_item;
render_mode unshaded;

// --- Recorte de Mundo (igual ao do campo) ---
uniform vec2 ground_global_position;
uniform vec2 ground_size;
uniform sampler2D mask_texture : hint_default_black;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// --- Parâmetros da Bomba ---
uniform float progresso : hint_range(0.0, 1.0) = 0.0; // 0 = centro, 1 = borda total
uniform float intensidade : hint_range(0.0, 1.0) = 0.5;
uniform float escurecimento : hint_range(0.0, 1.0) = 0.4; // Qto escurece o fundo

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    float dist = distance(UV, vec2(0.5));
    
    // --- 1. Máscara local circular (remove o quadrado do ColorRect) ---
    float mascara_circular = smoothstep(0.5, 0.48, dist);
    if (mascara_circular < 0.001) {
        discard;
    }
    
    // --- 2. Recorte do campo (World Space) ---
    if (ground_size.x > 0.01 && ground_size.y > 0.01) {
        vec2 ground_uv = (world_pos - (ground_global_position - ground_size * 0.5)) / ground_size;
        if (ground_uv.x < 0.0 || ground_uv.x > 1.0 || ground_uv.y < 0.0 || ground_uv.y > 1.0) {
            discard;
        }
        vec4 field = texture(mask_texture, ground_uv);
        if (field.a < 0.1) {
            discard;
        }
        mascara_circular *= field.a;
    }
    
    // --- 3. Captura e corrige o buffer (remove quadrado branco) ---
    vec4 screen = textureLod(screen_texture, SCREEN_UV, 0.0);
    if (screen.a > 0.0001) {
        screen.rgb /= screen.a;
    }
    
    // --- 4. Efeito de Cratera / Lava ---
    
    // Mascara de progresso: controla o quão longe a fissura se expandiu
    float raio_fissura = progresso * 0.5;
    float mascara_expansao = smoothstep(0.0, 0.02, dist - (raio_fissura - 0.02));
    
    // Fissuras radiais: usa seno com múltiplas frequências para criar rachaduras
    float angulo = atan(UV.y - 0.5, UV.x - 0.5);
    float rachadura_1 = sin(angulo * 8.0 + dist * 20.0) * 0.5 + 0.5;
    float rachadura_2 = sin(angulo * 5.0 + dist * 15.0 + TIME * 2.0) * 0.5 + 0.5;
    float rachadura_3 = sin(angulo * 12.0 - dist * 25.0 + TIME * 3.0) * 0.5 + 0.5;
    
    float veios = (rachadura_1 * 0.5 + rachadura_2 * 0.3 + rachadura_3 * 0.2);
    
    // Região central: queimada/escura
    float centro_queimado = smoothstep(raio_fissura, 0.0, dist);
    
    // Brilho laranja/vermelho nas bordas das rachaduras
    float brilho_veios = smoothstep(0.3, 0.8, veios) * smoothstep(raio_fissura + 0.05, raio_fissura - 0.05, dist);
    brilho_veios *= intensidade;
    
    // Pulsação no centro (como brasa viva)
    float pulsacao = sin(TIME * 4.0 + dist * 30.0) * 0.3 + 0.7;
    float brilho_centro = smoothstep(0.1, 0.0, dist) * pulsacao * intensidade * 0.6;
    
    // --- 5. Mistura com o fundo ---
    // Escurece o gramado onde a bomba passou
    vec3 cor_base = screen.rgb * (1.0 - centro_queimado * escurecimento);
    
    // Cores da lava (laranja → vermelho → amarelo)
    vec3 cor_lava = mix(
        vec3(0.8, 0.15, 0.05),   // Vermelho escuro (borda)
        vec3(1.0, 0.6, 0.05),    // Laranja/amarelo (centro)
        smoothstep(0.5, 0.0, dist)
    );
    
    // Aplica os veios de lava
    vec3 cor_final = mix(cor_base, cor_lava, brilho_veios);
    
    // Brilho central pulsante
    cor_final += vec3(1.0, 0.4, 0.05) * brilho_centro;
    
    // Brilho nas bordas das rachaduras (efeito glow)
    cor_final += cor_lava * brilho_veios * 0.4;
    
    COLOR.rgb = cor_final;
    COLOR.a = 1.0;
}